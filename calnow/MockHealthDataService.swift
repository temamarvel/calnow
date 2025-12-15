//
//  MockHealthDataService.swift
//  calnow
//
//  Created by Artem Denisov on 09.12.2025.
//


import Foundation
internal import HealthKit
import HealthKitDataService

final class MockHealthDataService: HealthDataService {
    // MARK: - Конфигурируемые "фейковые" данные
    
    /// Будем считать, что авторизация всегда проходит успешно
    var isAuthorized: Bool
    
    /// Последний вес (кг)
    var mockWeight: Double?
    
    /// Последний рост (см)
    var mockHeight: Double?
    
    /// Биологический пол
    var mockSex: HKBiologicalSex?
    
    /// Возраст
    var mockAge: Int?
    
    /// Базальный обмен (ккал/день), вокруг которого будем генерировать данные
    var baseBasalEnergy: Double
    
    /// Активная энергия (ккал/день) – базовый уровень
    var baseActiveEnergy: Double
    
    /// Фактор «шума», чтобы данные не были идеально ровными
    var dailyVariation: Double
    
    // MARK: - Инициализатор
    
    public init(
        isAuthorized: Bool = true,
        mockWeight: Double? = 90,
        mockHeight: Double? = 185,
        mockSex: HKBiologicalSex? = .male,
        mockAge: Int? = 35,
        baseBasalEnergy: Double = 1800,
        baseActiveEnergy: Double = 600,
        dailyVariation: Double = 150
    ) {
        self.isAuthorized = isAuthorized
        self.mockWeight = mockWeight
        self.mockHeight = mockHeight
        self.mockSex = mockSex
        self.mockAge = mockAge
        self.baseBasalEnergy = baseBasalEnergy
        self.baseActiveEnergy = baseActiveEnergy
        self.dailyVariation = dailyVariation
    }
    
    // MARK: - HealthDataService
    
    public func requestAuthorization() async throws -> AuthorizationResult {
        // ⚠️ Здесь использую .authorized как пример.
        // Если у твоего AuthorizationResult другие кейсы — просто поменяй на корректный.
        AuthorizationResult(isAuthorized: true)
    }
    
    public func fetchLatestWeight() async throws -> Double? {
        mockWeight
    }
    
    public func fetchLatestHeight() async throws -> Double? {
        mockHeight
    }
    
    public func fetchSex() throws -> HKBiologicalSex? {
        mockSex
    }
    
    public func fetchAge() throws -> Int? {
        mockAge
    }
    
    public func fetchEnergyToday(for id: HKQuantityTypeIdentifier) async throws -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let interval = DateInterval(start: today, end: Date())
        
        let daily = try await fetchEnergySums(for: id, in: interval, by: .day)
        // Для сегодняшнего дня берём значение по сегодняшней дате (или 0)
        return daily[today] ?? 0
    }
    
    public func fetchEnergySums(
        for id: HKQuantityTypeIdentifier,
        in interval: DateInterval,
        by: AggregatePeriod
    ) async throws -> [Date : Double] {
        let calendar = Calendar.current
        
        // Нормализуем начало/конец к началу суток
        let startDay = calendar.startOfDay(for: interval.start)
        let endDay = calendar.startOfDay(for: interval.end)
        
        guard let dayCount = calendar.dateComponents([.day], from: startDay, to: endDay).day else {
            return [:]
        }
        
        var result: [Date : Double] = [:]
        
        for offset in 0...dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            
            let base: Double
            switch id {
            case .basalEnergyBurned:
                base = baseBasalEnergy
            case .activeEnergyBurned:
                base = baseActiveEnergy
            default:
                // Если запросили другой тип — просто 0
                base = 0
            }
            
            // Небольшая псевдослучайная вариация, но детерминированная по дате,
            // чтобы при каждом вызове данные выглядели одинаково для одного интервала.
            let variation = pseudoRandomVariation(for: dayStart)
            let value = max(0, base + variation)
            result[dayStart] = value
        }
        
        return result
    }
    
    // MARK: - Вспомогательная функция для "шума"
    
    /// Детерминированный "шум" для даты, чтобы при одних и тех же датах
    /// мок возвращал одинаковые значения, но не идеально ровные.
    private func pseudoRandomVariation(for date: Date) -> Double {
        let timeInterval = date.timeIntervalSince1970
        // Преобразуем timeInterval в "почти случайное" число от -1 до 1
        let normalized = sin(timeInterval / 86_400) // период ~ 1 день
        return normalized * dailyVariation
    }
}
