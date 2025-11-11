//
//  HealthReadStatus.swift
//  calnow
//
//  Created by Артем Денисов on 11.11.2025.
//


import Foundation
import HealthKit

// MARK: - Публичные модели

/// Как в целом обстоят дела с чтением
enum HealthReadStatus {
    case none      // ничего из запрошенного читать нельзя
    case partial   // часть можно, часть нельзя
    case full      // всё можно
}

/// Результат проверки чтения
struct HealthReadResult {
    let status: HealthReadStatus

    /// Что именно разрешено/запрещено (по объектным типам HealthKit)
    let allowed: Set<HKObjectType>
    let denied:  Set<HKObjectType>

    /// Удобно для UI: мапа тип → Bool (true = можно читать)
    let perType: [HKObjectType: Bool]

    /// Нестандартные ошибки (например, Health недоступен на устройстве)
    let nonAuthErrors: [Error]
}

/// Конфигурация: какие типы хотим уметь читать
struct HealthReadConfig {
    var quantities:       [HKQuantityTypeIdentifier] = []
    var categories:       [HKCategoryTypeIdentifier] = []
    var characteristics:  [HKCharacteristicTypeIdentifier] = []
    var includeWorkouts:  Bool = false
}

// MARK: - Сервис

struct HealthAccessService {
    private let store: HKHealthStore

    init(store: HKHealthStore) { self.store = store }

    /// Главный метод: проверяет чтение по всем указанным типам
    func checkReadAccess(config: HealthReadConfig) async -> HealthReadResult {
        var perType: [HKObjectType: Bool] = [:]
        var nonAuthErrors: [Error] = []

        guard HKHealthStore.isHealthDataAvailable() else {
            // На этом устройстве чтение Health недоступно (iPad без "Здоровья", корпоративные ограничения и т.п.)
            return HealthReadResult(
                status: .none, allowed: [], denied: [],
                perType: [:], nonAuthErrors: [HKError(.errorHealthDataUnavailable)]
            )
        }

        // Собираем все HKObjectType из конфигурации
        var allTypes = Set<HKObjectType>()

        let quantityTypes: [HKQuantityType] = config.quantities.compactMap {
            HKObjectType.quantityType(forIdentifier: $0)
        }
        allTypes.formUnion(quantityTypes.map { $0 })

        let categoryTypes: [HKCategoryType] = config.categories.compactMap {
            HKObjectType.categoryType(forIdentifier: $0)
        }
        allTypes.formUnion(categoryTypes.map { $0 })

        if config.includeWorkouts {
            allTypes.insert(HKObjectType.workoutType())
        }

        // Характеристики не являются HKSampleType, но для итогов добавим их HKObjectType тоже
        let characteristicTypes: [HKCharacteristicType] = config.characteristics.compactMap {
            HKObjectType.characteristicType(forIdentifier: $0)
        }
        allTypes.formUnion(characteristicTypes.map { $0 })

        // Параллельно проверяем всё
        await withTaskGroup(of: (HKObjectType, Bool, Error?).self) { group in
            // quantities → лёгкая statistics query
            for q in quantityTypes {
                group.addTask {
                    let res = await probeSampleRead(sampleType: q, store: store)
                    switch res {
                        case .allowed:  return (q as HKObjectType, true,  nil)
                        case .denied:   return (q as HKObjectType, false, nil)
                        case .other(let err): return (q as HKObjectType, false, err)
                    }
                }
            }

            // categories → sample query (limit 1)
            for c in categoryTypes {
                group.addTask {
                    let result = await probeSampleRead(sampleType: c, store: store)
                    switch result {
                    case .allowed:  return (c as HKObjectType, true,  nil)
                    case .denied:   return (c as HKObjectType, false, nil)
                    case .other(let err): return (c as HKObjectType, false, err)
                    }
                }
            }

            // workouts → sample query (limit 1)
            if config.includeWorkouts {
                let w = HKObjectType.workoutType()
                group.addTask {
                    let result = await probeSampleRead(sampleType: w, store: store)
                    switch result {
                    case .allowed:  return (w as HKObjectType, true,  nil)
                    case .denied:   return (w as HKObjectType, false, nil)
                    case .other(let err): return (w as HKObjectType, false, err)
                    }
                }
            }

            // characteristics → читаем accessor-метод и ловим .errorAuthorizationDenied
            for ch in characteristicTypes {
                group.addTask {
                    let (ok, err) = probeCharacteristicRead(ch, store: store)
                    return (ch as HKObjectType, ok, err)
                }
            }

            for await (otype, ok, err) in group {
                perType[otype] = ok
                if let e = err, (e as? HKError)?.code != .errorAuthorizationDenied {
                    // не авторизационная (другая) ошибка → запомним отдельно
                    nonAuthErrors.append(e)
                }
            }
        }

        // Итоговые множества
        let allowed = Set(perType.compactMap { $0.value ? $0.key : nil })
        let denied  = Set(perType.compactMap { !$0.value ? $0.key : nil })

        let status: HealthReadStatus = {
            if allowed.isEmpty { return .none }
            if denied.isEmpty  { return .full }
            return .partial
        }()

        return HealthReadResult(
            status: status,
            allowed: allowed,
            denied: denied,
            perType: perType,
            nonAuthErrors: nonAuthErrors
        )
    }
}

// MARK: - Пробные проверки

/// Quantity: лёгкая statistics-заявка на последние 5 минут.
/// Возвращает true, если НЕТ ошибки .errorAuthorizationDenied (данных может не быть — это ок).
//private func probeQuantityRead(_ type: HKQuantityType, store: HKHealthStore) async -> Bool {
//    await withCheckedContinuation { cont in
//        let now = Date()
//        let pred = HKQuery.predicateForSamples(withStart: now.addingTimeInterval(-300), end: now)
//        let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, _, error in
//            if let e = error as? HKError, e.code == .errorAuthorizationDenied {
//                cont.resume(returning: false)
//            } else {
//                cont.resume(returning: true)
//            }
//        }
//        store.execute(q)
//    }
//}

/// Общая проверка для HKSampleType (category/workout): пытаемся прочитать 1 запись.
private enum SampleProbeResult { case allowed, denied, other(Error) }

private func probeSampleRead(sampleType: HKSampleType, store: HKHealthStore) async -> SampleProbeResult {
    await withCheckedContinuation { cont in
        let pred = HKQuery.predicateForSamples(withStart: .distantPast, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: sampleType, predicate: pred, limit: 1, sortDescriptors: [sort]) { _, _, error in
            if let e = error as? HKError {
                if e.code == .errorAuthorizationDenied { cont.resume(returning: .denied) }
                else { cont.resume(returning: .other(e)) }
            } else {
                cont.resume(returning: .allowed)
            }
        }
        store.execute(q)
    }
}

/// Характеристики читаются «аксессорами». Если ловим .errorAuthorizationDenied — доступа нет.
/// Возвращаем (ok, nonAuthError?)
private func probeCharacteristicRead(_ type: HKCharacteristicType, store: HKHealthStore) -> (Bool, Error?) {
    do {
        switch type.identifier {
        case HKCharacteristicTypeIdentifier.biologicalSex.rawValue:
            _ = try store.biologicalSex()
            return (true, nil)
        case HKCharacteristicTypeIdentifier.bloodType.rawValue:
            _ = try store.bloodType()
            return (true, nil)
        case HKCharacteristicTypeIdentifier.dateOfBirth.rawValue:
            _ = try store.dateOfBirthComponents()
            return (true, nil)
        case HKCharacteristicTypeIdentifier.fitzpatrickSkinType.rawValue:
            _ = try store.fitzpatrickSkinType()
            return (true, nil)
        case HKCharacteristicTypeIdentifier.wheelchairUse.rawValue:
            _ = try store.wheelchairUse()
            return (true, nil)
        case HKCharacteristicTypeIdentifier.activityMoveMode.rawValue:
            if #available(iOS 14.0, *) {
                _ = try store.activityMoveMode()
                return (true, nil)
            } else {
                return (false, HKError(.errorHealthDataUnavailable))
            }
        default:
            // неизвестная характеристика — считаем как недоступно
            return (false, HKError(.errorInvalidArgument))
        }
    } catch let e as HKError {
        if e.code == .errorAuthorizationDenied { return (false, nil) } // именно отказ в доступе
        return (false, e) // другая ошибка — вернём как nonAuthError
    } catch {
        return (false, error)
    }
}

// MARK: - Утилита для человекочитаемых названий (поможет в UI)

extension HKObjectType {
    var displayName: String {
        switch self {
        case let q as HKQuantityType:
            switch q.identifier {
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue: return "Активные калории"
            case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:  return "Базовые калории"
            case HKQuantityTypeIdentifier.stepCount.rawValue:          return "Шаги"
            default: return q.identifier
            }
        case let c as HKCategoryType:
            return "Категория: \(c.identifier)"
        case is HKWorkoutType:
            return "Тренировки"
        case let ch as HKCharacteristicType:
            switch ch.identifier {
            case HKCharacteristicTypeIdentifier.dateOfBirth.rawValue:   return "Дата рождения"
            case HKCharacteristicTypeIdentifier.biologicalSex.rawValue: return "Пол"
            case HKCharacteristicTypeIdentifier.bloodType.rawValue:     return "Группа крови"
            case HKCharacteristicTypeIdentifier.fitzpatrickSkinType.rawValue: return "Тип кожи"
            case HKCharacteristicTypeIdentifier.wheelchairUse.rawValue: return "Инвалидная коляска"
            case HKCharacteristicTypeIdentifier.activityMoveMode.rawValue: return "Режим Активности"
            default: return ch.identifier
            }
        default:
            return "\(self)"
        }
    }
}
