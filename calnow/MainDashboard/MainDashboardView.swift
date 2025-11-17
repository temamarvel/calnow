import SwiftUI
import SwiftData

// MARK: - MainDashboardView (использует секции)
struct MainDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var vm: MainDashboardViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ProfileSectionView(profile: vm.profile)
                CalculationsSectionView(bmr: vm.bmr, tdee: vm.tdee)
                TodaySectionView(basalToday: vm.basalToday, activeToday: vm.activeToday)
            }
            .navigationTitle("Сегодня")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.refreshToday()
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .accessibilityLabel("Обновить данные за сегодня")
                    .disabled(vm.isLoading)
                }
            }
            .onAppear { vm.onAppear(context: modelContext) }
            .alert("Ошибка", isPresented: Binding(
                get: { vm.alertMessage != nil },
                set: { if !$0 { vm.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.alertMessage ?? "")
            }
        }
    }
}

// MARK: - Секция «Профиль»
struct ProfileSectionView: View {
    let profile: UserProfile?
    
    var body: some View {
        Section("Профиль") {
            if let p = profile {
                LabeledContent("Пол") { Text(p.sex!.rawValue) }
                LabeledContent("Возраст") { Text("\(p.age) лет") }
                LabeledContent("Рост") { Text("\(Int(p.height ?? 0)) см") }
                LabeledContent("Вес") { Text(String(format: "%.1f кг", p.weight ?? 0)) }
                LabeledContent("Активность") { Text(p.activity!.rawValue) }
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
//#Preview("MainDashboard – Demo") {
//    // In-memory SwiftData
//    let schema = Schema([UserProfile.self])
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: schema, configurations: [config])
//    
//    // Единственный профиль
////    let ctx = ModelContext(container)
////    let p = UserProfile(sex: .male, age: 35, height: 185, weight: 90, activity: .moderate)
////    p.key = "UserProfileSingletonV1"
////    ctx.insert(p); try? ctx.save()
//    
//    MainDashboardContainer()
//        .modelContainer(container)
//        .environment(\.locale, .init(identifier: "ru_RU"))
//}
