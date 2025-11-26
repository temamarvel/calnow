//
//  HealthKitManager.swift
//  calnow
//
//  Created by Артем Денисов on 05.11.2025.
//


import Foundation
import HealthKit
internal import Combine

enum EnergyAverageWindow {
    case last7Days
    case last30Days
    case last180Days

    var days: Int {
        switch self {
        case .last7Days:   return 7
        case .last30Days:  return 30
        case .last180Days: return 180
        }
    }
}


/// Реализация протокола HealthKitServicing.
/// Используется в OnboardingViewModel для запроса доступа и импорта роста, веса, возраста и пола.
final class HealthKitManager: ObservableObject, HealthKitServicing {
    // MARK: - Private properties

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized: Bool = false

    // MARK: - Запрашиваемые типы данных
    private var readTypes: Set<HKObjectType> {
        var set = Set<HKObjectType>()
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            set.insert(weight)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            set.insert(height)
        }
        if let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            set.insert(dob)
        }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            set.insert(sex)
        }
        if let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            set.insert(activeEnergyBurned)
        }
        if let basalEnergyBurned = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            set.insert(basalEnergyBurned)
        }
        return set
    }
    
    // MARK: - Инициализация
    init() {}
    
    // MARK: - Авторизация HealthKit
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run { self.isAuthorized = false }
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            await MainActor.run {
                self.isAuthorized = false
            }
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Получение последнего веса (в кг)
    func fetchLatestWeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        
        // Swift sort descriptor, а не NSSortDescriptor
        let sort: SortDescriptor<HKQuantitySample> = .init(\.startDate, order: .reverse)
        let predicate = HKSamplePredicate.quantitySample(type: type)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [predicate],
            sortDescriptors: [sort],
            limit: 1
        )
        
        let results = try await descriptor.result(for: healthStore)
        guard let sample = results.first as? HKQuantitySample else { return nil }
        return sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }

    // MARK: - Получение последнего роста (в см)
    func fetchLatestHeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .height) else { return nil }
        
        let sort: SortDescriptor<HKQuantitySample> = .init(\.startDate, order: .reverse)
        let predicate = HKSamplePredicate.quantitySample(type: type)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [predicate],
            sortDescriptors: [sort],
            limit: 1
        )
        
        let results = try await descriptor.result(for: healthStore)
        guard let sample = results.first as? HKQuantitySample else { return nil }
        
        let meters = sample.quantity.doubleValue(for: .meter())
        return meters * 100.0
    }

    // MARK: - Получение возраста и пола
    func fetchDOBandSex() throws -> (age: Int?, sex: Sex?) {
        var calculatedAge: Int?
        var userSex: Sex?

        // Дата рождения
        if let components = try? healthStore.dateOfBirthComponents(),
           let birthDate = Calendar.current.date(from: components) {
            let now = Date()
            let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: now)
            calculatedAge = ageComponents.year
        }

        // Пол
        if let bio = try? healthStore.biologicalSex() {
            switch bio.biologicalSex {
            case .male:   userSex = .male
            case .female: userSex = .female
            default: break
            }
        }

        return (calculatedAge, userSex)
    }

    func fetchSex() throws -> Sex? {
        var userSex: Sex?
        
        // Пол
        if let bio = try? healthStore.biologicalSex() {
            switch bio.biologicalSex {
                case .male:   userSex = .male
                case .female: userSex = .female
                default: break
            }
        }
        
        return userSex
    }
    
    func fetchAge() throws -> Int? {
        var calculatedAge: Int?
        
        // Дата рождения
        if let components = try? healthStore.dateOfBirthComponents(),
           let birthDate = Calendar.current.date(from: components) {
            let now = Date()
            let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: now)
            calculatedAge = ageComponents.year
        }
        
        return calculatedAge
    }
    
    
    /// Сумма активной энергии за календарные сутки «сегодня» в ккал.
    func fetchActiveEnergyToday() async throws -> Double {
        try await sumEnergyToday(for: .activeEnergyBurned)
    }
    
    /// Сумма базальной энергии за календарные сутки «сегодня» в ккал.
    func fetchBasalEnergyToday() async throws -> Double {
        try await sumEnergyToday(for: .basalEnergyBurned)
    }
    
    
    func fetchTotalEnergyToday() async throws -> Double {
        async let basal = fetchBasalEnergyToday()
        async let active = fetchActiveEnergyToday()
        return try await basal + active
    }
    // MARK: - Внутренняя утилита
    

    
    private func sumEnergyToday(for id: HKQuantityTypeIdentifier) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        
        // границы сегодняшнего дня по локальному календарю/таймзоне
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKSamplePredicate.quantitySample(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        )
        
        // iOS 17+: типобезопасный дескриптор статистики с суммой
        let statsDescriptor = HKStatisticsQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum
        )
        
        let stats = try await statsDescriptor.result(for: healthStore)
        let kcal = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        return kcal
    }
    
    // helper: собрать дневную коллекцию по типу
    private func dailyBuckets(
        for id: HKQuantityTypeIdentifier,
        in interval: DateInterval
    ) async throws -> [(date: Date, kcal: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return [] }
        let cal = Calendar.current
        
        let predicate = HKSamplePredicate.quantitySample(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        )
        
        // суточные ведёрки
        let statsDesc = HKStatisticsCollectionQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum,
            anchorDate: cal.startOfDay(for: interval.start),
            intervalComponents: DateComponents(day: 1)
        )
        
        let collection = try await statsDesc.result(for: healthStore)
        var result: [(Date, Double)] = []
        collection.enumerateStatistics(from: interval.start, to: interval.end) { stats, _ in
            let date = stats.startDate
            let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            result.append((date, kcal))
        }
        return result
    }
    
    func dailyEnergyPoints(in interval: DateInterval) async throws -> [DayEnergyPoint] {
        async let active = dailyBuckets(for: .activeEnergyBurned, in: interval)
        async let basal  = dailyBuckets(for: .basalEnergyBurned,  in: interval)
        
        let (a, b) = try await (active, basal)
        
        // слить по дате
        let byDateA = Dictionary(uniqueKeysWithValues: a.map { ($0.date, $0.kcal) })
        let byDateB = Dictionary(uniqueKeysWithValues: b.map { ($0.date, $0.kcal) })
        
        // итерируем по дням интервала, чтобы были все дни (даже пустые)
        var points: [DayEnergyPoint] = []
        var day = Calendar.current.startOfDay(for: interval.start)
        let end = interval.end
        while day <= end {
            let aVal = byDateA[day] ?? 0
            let bVal = byDateB[day] ?? 0
            points.append(DayEnergyPoint(date: day, activeKcal: aVal, basalKcal: bVal))
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        }
        return points
    }
    


    
        func fetchAverageDailyEnergy(window: EnergyAverageWindow) async throws -> Double {
            let cal = Calendar.current

            let endDay = cal.startOfDay(for: Date())
            guard let startDay = cal.date(byAdding: .day,
                                          value: -window.days + 1,
                                          to: endDay) else {
                return 0
            }

            let interval = DateInterval(start: startDay, end: endDay)

            // Типы
            guard let activeType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                  let basalType  = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
                return 0
            }

            // ACTIVE
            let activePredicate = HKSamplePredicate.quantitySample(
                type: activeType,
                predicate: HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
            )

            let activeDesc = HKStatisticsCollectionQueryDescriptor(
                predicate: activePredicate,
                options: .cumulativeSum,
                anchorDate: cal.startOfDay(for: interval.start),
                intervalComponents: DateComponents(day: 1)
            )

            let activeCollection = try await activeDesc.result(for: healthStore)

            // BASAL
            let basalPredicate = HKSamplePredicate.quantitySample(
                type: basalType,
                predicate: HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
            )

            let basalDesc = HKStatisticsCollectionQueryDescriptor(
                predicate: basalPredicate,
                options: .cumulativeSum,
                anchorDate: cal.startOfDay(for: interval.start),
                intervalComponents: DateComponents(day: 1)
            )

            let basalCollection = try await basalDesc.result(for: healthStore)

            // Сборка дневных значений
            var dayCount = 0
            var totalKcal: Double = 0
            let unit = HKUnit.kilocalorie()

            for dayStart in interval.daysSequence() {
                let activeStats = activeCollection.statistics(for: dayStart)
                let basalStats  = basalCollection.statistics(for: dayStart)

                let active = activeStats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                let basal  = basalStats?.sumQuantity()?.doubleValue(for: unit) ?? 0

                let dayTotal = active + basal
                if dayTotal > 0 {
                    dayCount += 1
                    totalKcal += dayTotal
                }
            }

            guard dayCount > 0 else { return 0 }
            return totalKcal / Double(dayCount)
        }
    
    func basalEnergyPoints(for period: BasalChartPeriod) async throws -> [BasalEnergyPoint] {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -period.days, to: calendar.startOfDay(for: end))!
        let interval = DateInterval(start: start, end: end)

        // здесь можно использовать твой dailyBuckets(for: .basalEnergyBurned, in: interval)
        let buckets = try await dailyBuckets(for: .basalEnergyBurned, in: interval)

        return buckets.map { (date, kcal) in
            BasalEnergyPoint(date: date, basalKcal: kcal)
        }
        .sorted { $0.date < $1.date }
    }
    
    func activeEnergyPoints(for period: BasalChartPeriod) async throws -> [ActiveEnergyPoint] {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -period.days, to: calendar.startOfDay(for: end))!
        let interval = DateInterval(start: start, end: end)

        // здесь можно использовать твой dailyBuckets(for: .basalEnergyBurned, in: interval)
        let buckets = try await dailyBuckets(for: .activeEnergyBurned, in: interval)

        return buckets.map { (date, kcal) in
            ActiveEnergyPoint(date: date, activeKcal: kcal)
        }
        .sorted { $0.date < $1.date }
    }
    
}
