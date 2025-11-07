//
//  HealthKitManager.swift
//  calnow
//
//  Created by Артем Денисов on 05.11.2025.
//


import Foundation
import HealthKit

/// Реализация протокола HealthKitServicing.
/// Используется в OnboardingViewModel для запроса доступа и импорта роста, веса, возраста и пола.
final class HealthKitManager: HealthKitServicing {

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
            await MainActor.run {
                self.isAuthorized = true
            }
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
    func fetchDOBandSex() throws -> (age: Int?, sex: UserProfile.Sex?) {
        var calculatedAge: Int?
        var userSex: UserProfile.Sex?

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
    
    /// Сумма активной энергии за календарные сутки «сегодня» в ккал.
    func fetchActiveEnergyToday() async throws -> Double {
        try await sumEnergyToday(for: .activeEnergyBurned)
    }
    
    /// Сумма базальной энергии за календарные сутки «сегодня» в ккал.
    func fetchBasalEnergyToday() async throws -> Double {
        try await sumEnergyToday(for: .basalEnergyBurned)
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
}
