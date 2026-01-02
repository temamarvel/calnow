import SwiftUI
import HealthKitDataService
import SwiftData
import CircleProgressBar
internal import HealthKit


struct DetailCardView: View {
    let value: String
    let description: String
    
    
    var body: some View {
        VStack(alignment: .leading){
            Text(description).font(.headline)
                .foregroundStyle(.secondary)
            Text(value).font(.title).fontWeight(.bold)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        //.shadow(color: .appShadow.opacity(0.32), radius: 40, x: 0, y: 5)
    }
}

// MARK: - MainDashboardView (использует секции)
struct MainDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthDataService) private var healthKitService
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    
    // Для простоты берём первый профиль
    private var profile: UserProfile? { profiles.first }
    
    // Заглушки на случай отсутствия профиля
    private var bmr: Double {
        profile?.bmr ?? 1700   // имя свойства подставь своё
    }
    
    private var tdee: Double {
        profile?.tdee ?? 2900  // имя свойства подставь своё
    }
    
    // План: считаем, что план = tdee
    private var plannedTotal: Double {
        tdee
    }
    
    private var remainingTotal: Int {
        let delta = plannedTotal - (actualTotal ?? 0)
        return delta <= 0 ? 0 : Int(delta)
    }
    
    // Факт: возьми это из HealthKitManager, когда будет готово
    @State private var actualTotal: Double? = 1900
    @State private var average30Total: Double? = 0
    @State private var weekTotal: Double? = 0
    
    private let period = PredefinedDateInterval.last30Days
    
    private func getCurrentWeekInterval(calendar: Calendar = .current) -> DateInterval {
        let now = Date()
        
        // Интервал всей недели, в которую попадает "сейчас"
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return DateInterval(start: now, end: now)
        }
        
        // Нам нужно: с начала недели до текущего момента
        return DateInterval(start: weekInterval.start, end: now)
    }
    
    private func loadActualTotal() async {
        do {
            let basal = try await healthKitService.fetchEnergyToday(for: .basalEnergyBurned)
            let active = try await healthKitService.fetchEnergyToday(for: .activeEnergyBurned)
            actualTotal = basal + active
            
            let basalSum = try await healthKitService.fetchEnergySums(for: .basalEnergyBurned, in: period.daysInterval, by: .day).values.reduce(0, +)
            
            let activeSum = try await healthKitService.fetchEnergySums(for: .activeEnergyBurned, in: period.daysInterval, by: .day).values.reduce(0, +)
            average30Total = (basalSum + activeSum)/Double(period.daysCount)
            
            let currentWeekInterval = getCurrentWeekInterval()
            let weekBasalSum = try await healthKitService.fetchEnergySums(for: .basalEnergyBurned, in: currentWeekInterval, by: .day).values.reduce(0, +)
            let weekActiveSum = try await healthKitService.fetchEnergySums(for: .activeEnergyBurned, in: currentWeekInterval, by: .day).values.reduce(0, +)
            weekTotal = weekBasalSum + weekActiveSum
        } catch {
            print("Не удалось загрузить totalEnergyToday: \(error)")
            // Можно оставить actualTotal как nil, тогда вью возьмёт 1900
            // или явно поставить что-то:
            // actualTotal = 1900
        }
    }
    
    var body: some View {
        NavigationStack {
            
            
            ScrollView{
                VStack(alignment: .leading, spacing: 16) {
                    
                    
                    if profile == nil {
                        Text("Профиль не заполнен")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack{
                        ZStack{
                            CircleProgressView(progress: actualTotal!/plannedTotal, gradientColors: Color.surfProgressGradient,
                                               enableGlow: false, enableLighterTailColor: true)
                            VStack{
                                Text("Осталось")
                                Text("\(remainingTotal)")
                                    .font(.largeTitle.scaled(multiplier: 2.0))
                                    .fontWeight(.bold)
                            }.foregroundStyle(.secondary)
                            
                        }
                        
                        VStack{
                            DetailCardView(value: "\(Int(actualTotal ?? 0)) / \(Int(tdee)) ккал", description: "Потрачено")
                            
                            DetailCardView(value: "\(Int(average30Total ?? 0))", description: "Среднее за 30 дней")
                            
                            DetailCardView(value: "\(Int(weekTotal ?? 0))", description: "Потрачено с начала недели")
                        }
                    }
                    .padding()
//                    .background(
//                        RoundedRectangle(cornerRadius: 52, style: .continuous)
//                            .fill(.ultraThinMaterial) // или .regularMaterial на твой вкус
//                            .shadow(color: .appShadow.opacity(0.32), radius: 40, x: 0, y: 5)
//                    )
                    
                }
                .onChange(of: scenePhase) { old, phase in
                    if phase == .active {
                        Task {
                            await loadActualTotal()
                        }
                    }
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
            .appBackground()
        }
    }
}

struct MainDashboardPreviewWrapper: View {
    let container: ModelContainer
    @StateObject private var healthService = HealthKitDataService()
    
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
            .environmentObject(healthService)
    }
}

#Preview("Main dashboard") {
    MainDashboardPreviewWrapper()
}
