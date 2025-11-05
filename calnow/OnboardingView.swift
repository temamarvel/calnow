import SwiftUI
import SwiftData

struct OnboardingView: View {
    // SwiftData
    @Environment(\.modelContext) private var modelContext
    
    // VM
    @StateObject private var vm = OnboardingViewModel()
    
    // UI
    @FocusState private var focusedField: Field?
    
    enum Field { case age, height, weight }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Health
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: vm.hkAuthorized ? "checkmark.shield" : "exclamationmark.shield")
                            .foregroundStyle(vm.hkAuthorized ? .green : .orange)
                        Text(vm.hkAuthorized ? "Доступ к Здоровью разрешён" : "Нет доступа к Здоровью")
                        Spacer(minLength: 12)
                        if vm.isRequestingHK || vm.isImportingHK {
                            ProgressView()
                        }
                        Button(vm.hkAuthorized ? "Импортировать" : "Разрешить") {
                            if vm.hkAuthorized {
                                vm.importFromHealthTapped()
                            } else {
                                vm.requestHealthAccessAndImport()
                            }
                        }
                        .disabled(vm.isRequestingHK || vm.isImportingHK)
                    }
                } header: {
                    Text("Синхронизация с Health")
                } footer: {
                    Text("Импортируем рост, вес и дату рождения. Тексты причин — в Info.plist: NSHealthShareUsageDescription / NSHealthUpdateUsageDescription.")
                }
                
                // MARK: - Профиль
                Section("Профиль") {
                    Picker("Пол", selection: $vm.sex) {
                        ForEach(UserProfile.Sex.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .onChange(of: vm.sex) { _, new in vm.onSexChanged(new) }
                    
                    TextField("Возраст, лет", text: $vm.ageText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .age)
                        .onChange(of: vm.ageText) { _, new in vm.onAgeChanged(new) }
                    
                    TextField("Рост, см", text: $vm.heightText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .height)
                        .onChange(of: vm.heightText) { _, new in vm.onHeightChanged(new) }
                    
                    TextField("Вес, кг", text: $vm.weightText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .onChange(of: vm.weightText) { _, new in vm.onWeightChanged(new) }
                    
                    Picker("Активность", selection: $vm.activity) {
                        ForEach(UserProfile.ActivityLevel.allCases) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    .onChange(of: vm.activity) { _, new in vm.onActivityChanged(new) }
                }
                
                // MARK: - Результат
                Section("Результат") {
                    HStack {
                        Text("BMR (Миффлин—Сан Жеор)")
                        Spacer()
                        Text(vm.bmr > 0 ? "\(Int(vm.bmr)) ккал/день" : "—")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("TDEE (с учётом активности)")
                        Spacer()
                        Text(vm.tdee > 0 ? "\(Int(vm.tdee)) ккал/день" : "—")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Ваши данные")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") { focusedField = nil }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        focusedField = nil
                        vm.save(to: modelContext)
                    } label: {
                        HStack {
                            if vm.isSaving { ProgressView().padding(.trailing, 8) }
                            Text("Сохранить и продолжить")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.isSaving)
                }
            }
            .onAppear {
                vm.loadExistingIfAny(from: modelContext)
            }
            // MARK: - Alerts
            .alert("Сообщение", isPresented: Binding(
                get: { vm.alertMessage != nil },
                set: { if !$0 { vm.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.alertMessage ?? "")
            }
            // MARK: - Toast (простой)
            .overlay(alignment: .top) {
                if let text = vm.toastMessage {
                    ToastView(text: text) {
                        vm.toastMessage = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
            }
            .animation(.spring(duration: 0.3), value: vm.toastMessage)
        }
    }
}

// MARK: - Простой тост
private struct ToastView: View {
    let text: String
    var onDismiss: () -> Void
    @State private var isVisible = true
    
    var body: some View {
        Group {
            if isVisible {
                Text(text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .onAppear {
                        // Автоскрытие через 1.8s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { isVisible = false }
                            // Уведомим VM через лёгкую задержку, чтобы завершить анимацию
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onDismiss()
                            }
                        }
                    }
                    .accessibilityLabel(text)
            }
        }
    }
}

// MARK: - Превью с мок-сервисом и in-memory SwiftData
#Preview {
    // 1) Мок HealthKit
    final class HealthKitMock: HealthKitServicing {
        
        // MARK: - Публичные настройки мока
        
        /// Считаем ли, что доступ уже разрешён.
        /// Имитируется через requestAuthorization()
        private(set) var isAuthorized: Bool
        
        /// Возвращаемые значения (nil означает "данных нет")
        var mockWeightKg: Double?
        var mockHeightCm: Double?
        var mockAgeYears: Int?
        var mockSex: UserProfile.Sex?
        
        /// Имитируем задержку ответа (для ближе к реальности)
        var simulatedDelay: TimeInterval = 0.0
        
        /// Настроить, чтобы методы бросали ошибку (например, для проверки обработки ошибок в VM)
        var shouldFailAuthorization = false
        var shouldFailWeight = false
        var shouldFailHeight = false
        var shouldFailDOBSex = false
        
        // MARK: - Инициализация
        
        init(
            isAuthorized: Bool = true,
            weightKg: Double? = 90,
            heightCm: Double? = 185,
            ageYears: Int? = 35,
            sex: UserProfile.Sex? = .male,
            simulatedDelay: TimeInterval = 0.0
        ) {
            self.isAuthorized = isAuthorized
            self.mockWeightKg = weightKg
            self.mockHeightCm = heightCm
            self.mockAgeYears = ageYears
            self.mockSex = sex
            self.simulatedDelay = simulatedDelay
        }
        
        // Удобные пресеты
        static var demoMale: HealthKitMock {
            HealthKitMock(isAuthorized: true, weightKg: 90, heightCm: 185, ageYears: 35, sex: .male)
        }
        
        static var demoFemale: HealthKitMock {
            HealthKitMock(isAuthorized: true, weightKg: 62, heightCm: 170, ageYears: 29, sex: .female)
        }
        
        // MARK: - HealthKitServicing
        
        func requestAuthorization() async {
            // Имитируем задержку + успех/ошибку
            if simulatedDelay > 0 { try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000)) }
            
            if shouldFailAuthorization {
                await MainActor.run { self.isAuthorized = false }
                return
            }
            await MainActor.run { self.isAuthorized = true }
        }
        
        func fetchLatestWeight() async throws -> Double? {
            if simulatedDelay > 0 { try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000)) }
            if shouldFailWeight { throw MockError.failedToFetchWeight }
            return mockWeightKg
        }
        
        func fetchLatestHeight() async throws -> Double? {
            if simulatedDelay > 0 { try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000)) }
            if shouldFailHeight { throw MockError.failedToFetchHeight }
            return mockHeightCm
        }
        
        func fetchDOBandSex() throws -> (age: Int?, sex: UserProfile.Sex?) {
            if shouldFailDOBSex { throw MockError.failedToFetchDOBSex }
            return (mockAgeYears, mockSex)
        }
        
        // MARK: - Вспомогательное
        
        enum MockError: LocalizedError {
            case failedToFetchWeight
            case failedToFetchHeight
            case failedToFetchDOBSex
            
            var errorDescription: String? {
                switch self {
                    case .failedToFetchWeight: return "Не удалось получить вес (мок)."
                    case .failedToFetchHeight: return "Не удалось получить рост (мок)."
                    case .failedToFetchDOBSex: return "Не удалось получить дату рождения/пол (мок)."
                }
            }
        }
    }
    
    
    let schema = Schema([UserProfile.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    // Собираем вью и подсовываем VM с мок-сервисом
    let mock = HealthKitMock.demoMale
    let view = OnboardingView()
        .modelContainer(container)
    
    // Самый простой способ подменить VM — создать отдельный инициализатор у OnboardingView,
    // принимающий готовую VM. Если не хочешь менять вью, можно временно сделать
    // @StateObject var vm = OnboardingViewModel(health: HealthKitMock.demoMale)
    
    return view
        .environment(\.locale, .init(identifier: "ru_RU"))
}
