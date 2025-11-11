//
//  ChartsPeriod.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
internal import Combine

enum ChartsPeriod: String, CaseIterable, Identifiable {
    case week = "Неделя"
    case month = "Месяц"
    case halfYear = "Полгода"
    case year = "Год"
    var id: String { rawValue }

    func interval(now: Date = .now) -> DateInterval {
        let cal = Calendar.current
        switch self {
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now))!
            return DateInterval(start: start, end: now)
        case .month:
            let start = cal.date(byAdding: .month, value: -1, to: now)!
            return DateInterval(start: cal.startOfDay(for: start), end: now)
        case .halfYear:
            let start = cal.date(byAdding: .month, value: -6, to: now)!
            return DateInterval(start: cal.startOfDay(for: start), end: now)
        case .year:
            let start = cal.date(byAdding: .year, value: -1, to: now)!
            return DateInterval(start: cal.startOfDay(for: start), end: now)
        }
    }
}

struct DayEnergyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let activeKcal: Double
    let basalKcal: Double
}

@MainActor
final class EnergyChartsViewModel: ObservableObject {
    @Published var period: ChartsPeriod = .week
    @Published private(set) var series: [DayEnergyPoint] = []
    @Published private(set) var isLoading = false
    @Published var alertMessage: String?

    private let health: HealthKitServicing

    init(health: HealthKitServicing = HealthKitManager()) {
        self.health = health
    }

    func onAppear() {
        refresh()
    }

    func refresh() {
        Task {
            guard health.isAuthorized else {
                alertMessage = "Нет доступа к Здоровью. Разрешите доступ, чтобы построить графики."
                return
            }
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
