//
//  EnergyChartsViewModel.swift
//  calnow
//
//  Created by Артем Денисов on 15.11.2025.
//

import SwiftUI
import SwiftData
internal import Combine

@MainActor
final class EnergyChartsViewModel: ObservableObject {
    @Published var period: ChartsPeriod = .week
    @Published private(set) var series: [DayEnergyPoint] = []
    @Published private(set) var isLoading = false
    @Published var alertMessage: String?
    
    private let health: HealthKitServicing
    
    init(health: HealthKitServicing) {
        self.health = health
    }
    
    func onAppear() {
        refresh()
    }
    
    func refresh() {
        Task {
//            guard health.isAuthorized else {
//                alertMessage = "Нет доступа к Здоровью. Разрешите доступ, чтобы построить графики."
//                return
//            }
            isLoading = true
            defer { isLoading = false }
            do {
                let interval = period.interval()
                // Требуются методы протокола для дневных сумм
                let points = try await health.dailyEnergyPoints(in: interval)
                self.series = points
            } catch {
                alertMessage = "Не удалось загрузить данные: \(error.localizedDescription)"
            }
        }
    }
}
