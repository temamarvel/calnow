//
//  OnboardingViewModel.swift
//  calnow
//
//  Created by Артем Денисов on 05.11.2025.
//


import SwiftUI
import SwiftData
internal import Combine

/// Вью-модель онбординга: собирает профиль, подтягивает HealthKit, сохраняет единственную запись в SwiftData.
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Ввод пользователя (связан с TextField/Picker)
    @Published var sex: Sex = .male
    @Published var ageText: String = ""          // держим строкой, чтобы удобно вводить
    @Published var heightText: String = ""       // см
    @Published var weightText: String = ""       // кг
    @Published var activity: ActivityLevel = .moderate

    // MARK: - Вычисляемые для UI
    @Published private(set) var bmr: Double = 0
    @Published private(set) var tdee: Double = 0

    // MARK: - HealthKit / состояние
    @Published private(set) var hkAuthorized = false
    @Published private(set) var isRequestingHK = false
    @Published private(set) var isImportingHK = false

    // MARK: - Процессы/сообщения
    @Published private(set) var isSaving = false
    @Published var toastMessage: String?             // для кратких уведомлений
    @Published var alertMessage: String?             // для ошибок/алертов

    // MARK: - Зависимость
    var health: HealthKitServicing

    // MARK: - Форматирование чисел с учётом локали
    private let nf: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = .current
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.usesGroupingSeparator = false
        return nf
    }()

    // MARK: - Инициализация
    init(health: HealthKitServicing) {
        self.health = health
    }

    // MARK: - Публичные действия (вызываются из View)

    /// Подготовить вью-модель значениями из уже сохранённого профиля (если есть)
    func loadExistingIfAny(from context: ModelContext) {
        do {
            if let p = try context.getExistedUserProfile(){
                fill(from: p)
                recalc()
            }
        } catch {
            alertMessage = "Не удалось загрузить профиль: \(error.localizedDescription)"
        }
    }

    /// Запросить доступ к HealthKit и, если успешно, импортировать данные.
    func requestHealthAccessAndImport() {
        Task {
            isRequestingHK = true
            defer { isRequestingHK = false }
            await healthRequest()
            if hkAuthorized {
                await importFromHealth()
            }
        }
    }

    /// Только импорт (если уже авторизованы)
    func importFromHealthTapped() {
        Task { await importFromHealth() }
    }

    /// Вызывать на изменениях полей ввода (age/height/weight/sex/activity)
    func recalc() {
        guard
            let age = parseInt(ageText),
            let h = parseDouble(heightText),
            let w = parseDouble(weightText)
        else {
            bmr = 0
            tdee = 0
            return
        }
        let base = 10*w + 6.25*h - 5*Double(age)
        bmr = (sex == .male) ? (base + 5) : (base - 161)
        tdee = bmr * activity.multiplier
    }

    /// Сохранить данные в единственной записи UserProfile (single-row upsert).
    func save(to context: ModelContext) {
        do {
            isSaving = true
            defer { isSaving = false }
            let (age, h, w) = try validatedNumbers()
            try context.updateUserProfile { p in
                p.sex = sex
                p.age = age
                p.height = h
                p.weight = w
                p.activity = activity
            }
            toastMessage = "Профиль сохранён"
        } catch let e as ValidationError {
            alertMessage = e.message
        } catch {
            alertMessage = "Не удалось сохранить: \(error.localizedDescription)"
        }
    }

    // MARK: - Привязка ввода к пересчёту (вызывай из .onChange в View)
    func onAgeChanged(_ new: String)       { ageText = new;     recalc() }
    func onHeightChanged(_ new: String)    { heightText = new;  recalc() }
    func onWeightChanged(_ new: String)    { weightText = new;  recalc() }
    func onSexChanged(_ new: Sex) { sex = new;      recalc() }
    func onActivityChanged(_ new: ActivityLevel) { activity = new; recalc() }

    // MARK: - Приватные: HealthKit

    private func healthRequest() async {
        do {
            await health.requestAuthorization()
            hkAuthorized = health.isAuthorized
            if !hkAuthorized {
                alertMessage = "Доступ к Здоровью не предоставлен."
            }
        } catch {
            hkAuthorized = false
            alertMessage = "Ошибка запрашивания доступа к Здоровью: \(error.localizedDescription)"
        }
    }

    private func importFromHealth() async {
        guard health.isAuthorized else {
            alertMessage = "Нет доступа к Здоровью. Разрешите доступ, чтобы импортировать данные."
            return
        }
        isImportingHK = true
        defer { isImportingHK = false }

        do {
            // Вес
            if let w = try await health.fetchLatestWeight() {
                weightText = nf.string(from: NSNumber(value: w)) ?? "\(w)"
            }
            // Рост (м в HK → см у нас)
            if let h = try await health.fetchLatestHeight() {
                heightText = nf.string(from: NSNumber(value: h)) ?? "\(h)"
            }
            // Возраст/пол
//            let (age, s) = try health.fetchDOBandSex()
//            if let s { sex = s }
//            if let age { ageText = "\(age)" }

            recalc()
            toastMessage = "Данные импортированы из Здоровья"
        } catch {
            alertMessage = "Не удалось импортировать из Здоровья: \(error.localizedDescription)"
        }
    }

    // MARK: - Приватные: валидация/формат

    private enum ValidationError: Error {
        case invalidNumbers(String)
        var message: String {
            switch self {
            case .invalidNumbers(let m): return m
            }
        }
    }

    private func validatedNumbers() throws -> (age: Int, height: Double, weight: Double) {
        guard let age = parseInt(ageText), age >= 10, age <= 120 else {
            throw ValidationError.invalidNumbers("Возраст должен быть от 10 до 120 лет.")
        }
        guard let height = parseDouble(heightText), height >= 50, height <= 260 else {
            throw ValidationError.invalidNumbers("Рост должен быть от 50 до 260 см.")
        }
        guard let weight = parseDouble(weightText), weight >= 20, weight <= 350 else {
            throw ValidationError.invalidNumbers("Вес должен быть от 20 до 350 кг.")
        }
        return (age, height, weight)
    }

    /// Парсинг double с учётом запятой/точки в текущей локали
    private func parseDouble(_ s: String) -> Double? {
        if let n = nf.number(from: s)?.doubleValue { return n }
        // fallback: заменим запятую на точку
        let dot = s.replacingOccurrences(of: ",", with: ".")
        return Double(dot)
    }

    private func parseInt(_ s: String) -> Int? {
        // NumberFormatter корректнее работает для локалей с не-ASCII цифрами
        if let n = nf.number(from: s)?.intValue { return n }
        return Int(s.filter { $0.isNumber })
    }

    // MARK: - Заполнение из сохранённой модели
    private func fill(from p: UserProfile) {
//        sex = p.sex
//        activity = p.activity
//        ageText = "\(p.age)"
//        heightText = nf.string(from: NSNumber(value: p.height)) ?? "\(p.height)"
//        weightText = nf.string(from: NSNumber(value: p.weight)) ?? "\(p.weight)"
    }
}

// MARK: - Протокол для HealthKit (удобно подменять в превью/тестах)
protocol HealthKitServicing: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization() async
    func fetchLatestWeight() async throws -> Double?     // кг
    func fetchLatestHeight() async throws -> Double?     // см
    func fetchSex() throws -> Sex?
    func fetchAge() throws -> Int?
    func fetchActiveEnergyToday() async throws -> Double
    func fetchBasalEnergyToday() async throws -> Double
    func dailyEnergyPoints(in interval: DateInterval) async throws -> [DayEnergyPoint]
    func fetchAverageDailyEnergy(window: EnergyAverageWindow) async throws -> Double
}
