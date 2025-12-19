//
//  HealthKitDataUserBMRService.swift
//  calnow
//
//  Created by Артем Денисов on 19.12.2025.
//

import HealthKitDataService
internal import Combine
internal import HealthKit
import SwiftUI
import SwiftData

final class HealthKitDataUserBMRService: ObservableObject, HealthDataService{
    private let bmr: Double
    
    private var basalEnergyNow: Double {
        (Double(Calendar.current.component(.hour, from: Date())) / 24.0) * bmr
    }
    
    private let baseHealthDataService: any HealthDataService
    
    init(baseHealthDataService: any HealthDataService, bmr: Double) {
        self.baseHealthDataService = baseHealthDataService
        self.bmr = bmr
    }
    
    
    func requestAuthorization() async throws -> AuthorizationResult {
        try await baseHealthDataService.requestAuthorization()
    }
    
    func fetchLatestWeight() async throws -> Double? {
        try await baseHealthDataService.fetchLatestWeight()
    }
    
    func fetchLatestHeight() async throws -> Double? {
        try await baseHealthDataService.fetchLatestHeight()
    }
    
    func fetchSex() throws -> HKBiologicalSex? {
        try baseHealthDataService.fetchSex()
    }
    
    func fetchAge() throws -> Int? {
        try baseHealthDataService.fetchAge()
    }
    
    func fetchEnergyToday(for id: HKQuantityTypeIdentifier) async throws -> Double {
        if id == .basalEnergyBurned{
            return basalEnergyNow
        }
        return try await baseHealthDataService.fetchEnergyToday(for: id)
    }
    
    func fetchEnergySums(for id: HKQuantityTypeIdentifier, in interval: DateInterval, by: AggregatePeriod) async throws -> [Date : Double] {
        if id == .basalEnergyBurned {
            return getBasalEnergyData(for: interval, by: by)
        }
        return try await baseHealthDataService.fetchEnergySums(for: id, in: interval, by: by)
    }
    
    func getBasalEnergyData(for interval: DateInterval, by aggregate: AggregatePeriod) -> [Date: Double] {
        return Dictionary(
            uniqueKeysWithValues: interval.periods(by: aggregate).lazy.map { date in
                (date, Calendar.current.isDateInToday(date) ? self.basalEnergyNow : self.bmr)
            }
        )
    }
}
