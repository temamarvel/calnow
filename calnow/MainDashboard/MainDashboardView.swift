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
    @State private var averageTotal: Double? = 0
    
    private func loadActualTotal() async {
        do {
            actualTotal = try await healthKitManager.fetchTotalEnergyToday()
            averageTotal = try await healthKitManager.fetchAverageDailyEnergy(window: .last30Days)
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
                
                
                if profile == nil {
                    Text("Профиль не заполнен")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ZStack{
                    CircleProgressView(progress: actualTotal!/plannedTotal)
                    
                    VStack{
                        Text("\(Int(actualTotal!))").font(.title).fontWeight(.bold).foregroundStyle(.secondary)
                        
                        Divider().frame(height: 5).overlay(.pink).clipShape(.capsule)
                        
                        Text("\(Int(plannedTotal))").font(.title).fontWeight(.bold).foregroundStyle(.secondary)
                    }.fixedSize(horizontal: true, vertical: false)
                }
                
                
                Text("Avarage \(averageTotal)")
                
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
