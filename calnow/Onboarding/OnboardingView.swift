import SwiftUI
import HealthKitDataService
import SwiftData

struct OnboardingContainer: View {
    @Environment(\.healthDataService) private var healthKitService
    var body: some View {
        OnboardingView(health: healthKitService) // ← передаём зависимость
    }
}

struct OnboardingView: View {
    // SwiftData
    @Environment(\.modelContext) private var modelContext
    
    init(health: HealthDataService) {
        //_vm = StateObject(wrappedValue: OnboardingViewModel(health: health))
        _vm = StateObject(wrappedValue: OnboardingViewModel(health: health))
    }
    
    // VM
    @StateObject private var vm : OnboardingViewModel
    
    // UI
    @FocusState private var focusedField: Field?
        
    enum Field { case age, height, weight }
    
    var body: some View {
        Text("old onboarding!")
//        NavigationStack {
//            Form {
//                // MARK: - Health
//                Section {
//                    HStack(spacing: 12) {
//                        Image(systemName: vm.hkAuthorized ? "checkmark.shield" : "exclamationmark.shield")
//                            .foregroundStyle(vm.hkAuthorized ? .green : .orange)
//                        Text(vm.hkAuthorized ? "Доступ к Здоровью разрешён" : "Нет доступа к Здоровью")
//                        Spacer(minLength: 12)
//                        if vm.isRequestingHK || vm.isImportingHK {
//                            ProgressView()
//                        }
//                        Button(vm.hkAuthorized ? "Импортировать" : "Разрешить") {
//                            if vm.hkAuthorized {
//                                vm.importFromHealthTapped()
//                            } else {
//                                vm.requestHealthAccessAndImport()
//                            }
//                        }
//                        .disabled(vm.isRequestingHK || vm.isImportingHK)
//                    }
//                } header: {
//                    Text("Синхронизация с Health")
//                } footer: {
//                    Text("Импортируем рост, вес и дату рождения. Тексты причин — в Info.plist: NSHealthShareUsageDescription / NSHealthUpdateUsageDescription.")
//                }
//                
//                // MARK: - Профиль
//                Section("Профиль") {
//                    Picker("Пол", selection: $vm.sex) {
//                        ForEach(UserProfile.Sex.allCases) { s in
//                            Text(s.rawValue).tag(s)
//                        }
//                    }
//                    .onChange(of: vm.sex) { _, new in vm.onSexChanged(new) }
//                    
//                    TextField("Возраст, лет", text: $vm.ageText)
//                        .keyboardType(.numberPad)
//                        .focused($focusedField, equals: .age)
//                        .onChange(of: vm.ageText) { _, new in vm.onAgeChanged(new) }
//                    
//                    TextField("Рост, см", text: $vm.heightText)
//                        .keyboardType(.decimalPad)
//                        .focused($focusedField, equals: .height)
//                        .onChange(of: vm.heightText) { _, new in vm.onHeightChanged(new) }
//                    
//                    TextField("Вес, кг", text: $vm.weightText)
//                        .keyboardType(.decimalPad)
//                        .focused($focusedField, equals: .weight)
//                        .onChange(of: vm.weightText) { _, new in vm.onWeightChanged(new) }
//                    
//                    Picker("Активность", selection: $vm.activity) {
//                        ForEach(UserProfile.ActivityLevel.allCases) { a in
//                            Text(a.rawValue).tag(a)
//                        }
//                    }
//                    .onChange(of: vm.activity) { _, new in vm.onActivityChanged(new) }
//                }
//                
//                // MARK: - Результат
//                Section("Результат") {
//                    HStack {
//                        Text("BMR (Миффлин—Сан Жеор)")
//                        Spacer()
//                        Text(vm.bmr > 0 ? "\(Int(vm.bmr)) ккал/день" : "—")
//                            .fontWeight(.semibold)
//                    }
//                    HStack {
//                        Text("TDEE (с учётом активности)")
//                        Spacer()
//                        Text(vm.tdee > 0 ? "\(Int(vm.tdee)) ккал/день" : "—")
//                            .fontWeight(.semibold)
//                    }
//                }
//            }
//            .navigationTitle("Ваши данные")
//            .toolbar {
//                ToolbarItemGroup(placement: .keyboard) {
//                    Spacer()
//                    Button("Готово") { focusedField = nil }
//                }
//                ToolbarItem(placement: .bottomBar) {
//                    Button {
//                        focusedField = nil
//                        vm.save(to: modelContext)
//                    } label: {
//                        HStack {
//                            if vm.isSaving { ProgressView().padding(.trailing, 8) }
//                            Text("Сохранить и продолжить")
//                                .fontWeight(.semibold)
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .disabled(vm.isSaving)
//                }
//            }
//            .onAppear {
//                vm.loadExistingIfAny(from: modelContext)
//            }
//            // MARK: - Alerts
//            .alert("Сообщение", isPresented: Binding(
//                get: { vm.alertMessage != nil },
//                set: { if !$0 { vm.alertMessage = nil } }
//            )) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(vm.alertMessage ?? "")
//            }
//            // MARK: - Toast (простой)
//            .overlay(alignment: .top) {
//                if let text = vm.toastMessage {
//                    ToastView(text: text) {
//                        vm.toastMessage = nil
//                    }
//                    .transition(.move(edge: .top).combined(with: .opacity))
//                    .padding(.top, 8)
//                }
//            }
//            .animation(.spring(duration: 0.3), value: vm.toastMessage)
//        }
    }
}

// MARK: - Простой тост
struct ToastView: View {
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
    
    let schema = Schema([UserProfile.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    
    // Собираем вью и подсовываем VM с мок-сервисом
    let view = OnboardingContainer()
        .modelContainer(container)
    
    // Самый простой способ подменить VM — создать отдельный инициализатор у OnboardingView,
    // принимающий готовую VM. Если не хочешь менять вью, можно временно сделать
    // @StateObject var vm = OnboardingViewModel(health: HealthKitMock.demoMale)
    
    return view
        .environment(\.locale, .init(identifier: "ru_RU"))
}
