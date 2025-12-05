import SwiftUI
import SwiftData
import CircleProgressBar


struct DetailCardView: View {
    let value: String
    let description: String
    
    
    var body: some View {
        VStack(alignment: .leading){
            Text(description).font(.headline)
                .foregroundStyle(.secondary)
            Text(value).font(.title).fontWeight(.bold)
                .foregroundStyle(.secondary)
        }.padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

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
    
    private var remainingTotal: Int {
        let delta = plannedTotal - (actualTotal ?? 0)
        return delta <= 0 ? 0 : Int(delta)
    }
    
    // Факт: возьми это из HealthKitManager, когда будет готово
    @State private var actualTotal: Double? = 1900
    @State private var averageTotal: Double? = 0
    @State private var averageTotal2: Double? = 0
    @State private var weekTotal: Double? = 0
    
    private func loadActualTotal() async {
        do {
            actualTotal = try await healthKitManager.fetchTotalEnergyToday()
            averageTotal = try await healthKitManager.fetchAverageDailyEnergy(window: .last30Days)
            averageTotal2 = try await healthKitManager.fetchAverageDailyEnergy(window: .last7Days)
            weekTotal = try await healthKitManager.fetchDailyEnergy(window: .last7Days)
        } catch {
            print("Не удалось загрузить totalEnergyToday: \(error)")
            // Можно оставить actualTotal как nil, тогда вью возьмёт 1900
            // или явно поставить что-то:
            // actualTotal = 1900
        }
    }
    
    var body: some View {
        NavigationStack {
            
            ZStack{
                Color.appBackground
                    .ignoresSafeArea()
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
                                                   enableGlow: true)
                                VStack{
                                    Text("\(remainingTotal)")
                                        .font(.scaledSize(multiplier: 2, relativeTo: .largeTitle))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                }
                                
                            }
                            
                            VStack{
                                DetailCardView(value: "\(Int(actualTotal ?? 0)) / \(Int(tdee)) ккал", description: "Потрачено")
                                
                                DetailCardView(value: "\(Int(averageTotal ?? 0))", description: "Среднее за месяц")
                                
                                DetailCardView(value: "\(Int(averageTotal2 ?? 0))", description: "Среднее за 7 дней")
                                
                                DetailCardView(value: "\(Int(weekTotal ?? 0))", description: "Сумма за 7 дней")
                                
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 52, style: .continuous)
                                .fill(.ultraThinMaterial) // или .regularMaterial на твой вкус
                        ).shadow(color: .appShadow.opacity(0.12), radius: 40, x: 0, y: 5)
                        
                        //Spacer()
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
    }
}

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
