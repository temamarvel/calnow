//
//  MainDashboardViewModel.swift
//  calnow
//
//  Created by Артем Денисов on 07.11.2025.
//


import SwiftUI
import SwiftData
internal import Combine

@MainActor
final class MainDashboardViewModel: ObservableObject {
    // Профиль пользователя (single-row)
    @Published private(set) var profile: UserProfile?

    // Отображаемые метрики
    @Published private(set) var bmr: Double = 0
    @Published private(set) var tdee: Double = 0
    @Published private(set) var basalToday: Double = 0   // ккал
    @Published private(set) var activeToday: Double = 0  // ккал

    // UI состояния
    @Published private(set) var isLoading = false
    @Published var alertMessage: String?

    private let health: HealthKitServicing

    init(health: HealthKitServicing = HealthKitManager()) {
        self.health = health
    }

    func loadProfile(from context: ModelContext) {
        do {
            let p = try context.getUserProfile()
            profile = p
            // можно прямо брать из модели (computed):
            bmr = p.bmr
            tdee = p.tdee
        } catch {
            alertMessage = "Не удалось загрузить профиль: \(error.localizedDescription)"
        }
    }

    /// Подтянуть «сегодняшние» калории (basal/active). Требует доступ к HealthKit.
    func refreshToday() {
        Task {
            guard health.isAuthorized else {
                alertMessage = "Нет доступа к Здоровью. Разрешите доступ в настройках."
                return
            }
            isLoading = true
            defer { isLoading = false }
            do {
                async let a = health.fetchActiveEnergyToday()
                async let b = health.fetchBasalEnergyToday()
                // Если health — не HealthKitManager (например, мок), дадим ему аналогичные методы:
                let active = try await a
                let basal  = try await b
                self.activeToday = active
                self.basalToday  = basal
            } catch {
                alertMessage = "Не удалось обновить данные за сегодня: \(error.localizedDescription)"
            }
        }
    }

    /// Универсальный метод для первого запуска экрана
    func onAppear(context: ModelContext) {
        loadProfile(from: context)
        // если уже есть доступ — подтянем данные
        if health.isAuthorized {
            refreshToday()
        }
    }
}
