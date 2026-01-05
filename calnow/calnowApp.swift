import SwiftUI
import HealthKitDataService
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @State private var showOnboarding: Bool? = nil
    var body: some View {
        Group {
            ZStack{
                Color.appBackground
                    .ignoresSafeArea()
                if let showOnboarding {
                    if showOnboarding {
                        OnboardingMainView {
                            self.showOnboarding = false
                        }
                    } else {
                        DashboardRootView()
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            showOnboarding = profiles.isEmpty
        }
    }
}

private struct HealthDataServiceKey: EnvironmentKey {
    // Значение по умолчанию – можно поставить простую заглушку,
    // чтобы превью не падали, если забудешь передать сервис.
    static var defaultValue: any HealthDataService = MockHealthDataService()
}

extension EnvironmentValues {
    var healthDataService: any HealthDataService {
        get { self[HealthDataServiceKey.self] }
        set { self[HealthDataServiceKey.self] = newValue }
    }
}


@main
struct CalNowApp: App {
    private let container: ModelContainer
    
    @AppStorage("app_theme")
    private var theme: AppTheme = .system
    
    @StateObject private var healthKitService: HealthKitDataUserBMRService
    
//    = {
//        let healthKitDataService = HealthKitDataService()
//        return HealthKitDataUserBMRService(
//            baseHealthDataService: healthKitDataService,
//        )
//    }()= {
//        let healthKitDataService = HealthKitDataService()
//        return HealthKitDataUserBMRService(
//            baseHealthDataService: healthKitDataService,
//        )
//    }()
    
    static func loadFirstProfileBMR(container: ModelContainer) throws -> Double {
        let context = container.mainContext
        
        var d = FetchDescriptor<UserProfile>()
        d.fetchLimit = 1
        
        return try context.fetch(d).first?.bmr ?? 0
    }
    
    init() {
        container = try! ModelContainer(for: UserProfile.self)
        
        let healthKitDataService = HealthKitDataService()
        
        let bmr: Double
        do {
            bmr = try CalNowApp.loadFirstProfileBMR(container: container)
        } catch {
            print("Не удалось загрузить BMR: \(error)")
            bmr = 0
        }
        
        let service = HealthKitDataUserBMRService(
            baseHealthDataService: healthKitDataService,
            bmr: bmr
        )
        
        _healthKitService = StateObject(wrappedValue: service)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.healthDataService, healthKitService)
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(container)
    }
}
