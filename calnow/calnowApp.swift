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
                        DashboardRootContainer()
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
    @StateObject private var healthKitService = HealthKitDataService()
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: UserProfile.self)
        .environment(\.healthDataService, healthKitService)
    }
}
