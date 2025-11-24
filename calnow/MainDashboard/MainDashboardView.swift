import SwiftUI
import SwiftData
import CircleProgressBar

// MARK: - MainDashboardView (использует секции)
struct MainDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var profiles: [UserProfile]
    
    // Для простоты берём первый профиль
    private var profile: UserProfile? { profiles.first }
    
    // Заглушки на случай отсутствия профиля
    private var bmr: Double {
        profile?.bmr ?? 1700   // имя свойства подставь своё
    }
    
    private var tdee: Double {
        profile?.tdee ?? 2500  // имя свойства подставь своё
    }
    
    // План: считаем, что план = tdee
    private var plannedTotal: Double {
        tdee
    }
    
    // Факт: возьми это из HealthKitManager, когда будет готово
    @State private var actualTotal: Double? = 1900
    
    private func loadActualTotal() async {
        do {
            let total = try await healthKitManager.fetchTotalEnergyToday()
            actualTotal = total
        } catch {
            print("Не удалось загрузить totalEnergyToday: \(error)")
            // Можно оставить actualTotal как nil, тогда вью возьмёт 1900
            // или явно поставить что-то:
            // actualTotal = 1900
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Сегодня")
                    .font(.title.bold())
                
                if profile == nil {
                    Text("Профиль не заполнен")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                CircleProgressView(progress: plannedTotal/actualTotal!)
                
//                EnergyBarView(
//                    title: "План на день",
//                    tdee: tdee,
//                    bmr: bmr,
//                    total: plannedTotal
//                )
//                
//                EnergyBarView(
//                    title: "Факт сейчас",
//                    tdee: tdee,
//                    bmr: bmr,
//                    total: actualTotal ?? 999
//                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Сегодня")
            .task {
                await loadActualTotal()
            }
//            .toolbar {
//                ToolbarItem(placement: .primaryAction) {
//                    Button {
//                        vm.refreshToday()
//                    } label: {
//                        if vm.isLoading {
//                            ProgressView()
//                        } else {
//                            Image(systemName: "arrow.clockwise")
//                        }
//                    }
//                    .accessibilityLabel("Обновить данные за сегодня")
//                    .disabled(vm.isLoading)
//                }
//            }
//            .onAppear { vm.onAppear(context: modelContext) }
//            .alert("Ошибка", isPresented: Binding(
//                get: { vm.alertMessage != nil },
//                set: { if !$0 { vm.alertMessage = nil } }
//            )) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(vm.alertMessage ?? "")
//            }
        }
    }
}

// MARK: - Секция «Профиль»
struct ProfileSectionView: View {
    let profile: UserProfile?
    
    var body: some View {
        Section("Профиль") {
            if let p = profile {
                LabeledContent("Пол") { Text(p.sex.rawValue) }
                LabeledContent("Возраст") { Text("\(p.age) лет") }
                LabeledContent("Рост") { Text("\(Int(p.height)) см") }
                LabeledContent("Вес") { Text(String(format: "%.1f кг", p.weight)) }
                LabeledContent("Активность") { Text(p.activity.rawValue) }
            } else {
                Text("Профиль не найден")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Секция «Расчёты»
struct CalculationsSectionView: View {
    let bmr: Double
    let tdee: Double
    
    var body: some View {
        Section("Расчёты") {
            LabeledContent("BMR (Миффлин—Сан Жеор)") {
                Text(bmr > 0 ? "\(Int(bmr)) ккал/день" : "—")
                    .fontWeight(.semibold)
            }
            LabeledContent("TDEE (с учётом активности)") {
                Text(tdee > 0 ? "\(Int(tdee)) ккал/день" : "—")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Секция «Сегодня»
struct TodaySectionView: View {
    let basalToday: Double
    let activeToday: Double
    
    private var totalToday: Int { Int(basalToday + activeToday) }
    
    var body: some View {
        Section("Сегодня") {
            HStack {
                Text("Базальный расход")
                Spacer()
                Text("\(Int(basalToday)) ккал").fontWeight(.semibold)
            }
            HStack {
                Text("Активная энергия")
                Spacer()
                Text("\(Int(activeToday)) ккал").fontWeight(.semibold)
            }
            HStack {
                Text("Всего за сегодня")
                Spacer()
                Text("\(totalToday) ккал").fontWeight(.bold)
            }
        }
    }
}

// MARK: - Превью секций
//#Preview("Profile Section") {
//    let schema = Schema([UserProfile.self])
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: schema, configurations: [config])
//    let ctx = ModelContext(container)
//    let p = UserProfile(sex: .male, age: 35, height: 185, weight: 90, activity: .moderate)
//    p.key = "UserProfileSingletonV1"
//    ctx.insert(p); try? ctx.save()
//    
//    List { ProfileSectionView(profile: p) }
//        .modelContainer(container)
//        .environment(\.locale, .init(identifier: "ru_RU"))
//}

//#Preview("Calculations Section") {
//    List { CalculationsSectionView(bmr: 1880, tdee: 2914) }
//        .environment(\.locale, .init(identifier: "ru_RU"))
//}

//#Preview("Today Section") {
//    List { TodaySectionView(basalToday: 1720, activeToday: 430) }
//        .environment(\.locale, .init(identifier: "ru_RU"))
//}

// MARK: - Общее превью MainDashboardView с мок-данными
struct MainDashboardPreviewWrapper: View {
    let container: ModelContainer
    @StateObject private var healthManager = HealthKitManager()

    init() {
        // in-memory контейнер
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: UserProfile.self, configurations: config)

        let context = container.mainContext

        // тестовый профиль — подгони под свою модель
        let profile = UserProfile()
//        profile.bmr = 1700
//        profile.tdee = 2600
        context.insert(profile)
    }

    var body: some View {
        MainDashboardView()
            .modelContainer(container)
            .environmentObject(healthManager)
    }
}

#Preview("Main dashboard") {
    MainDashboardPreviewWrapper()
}
