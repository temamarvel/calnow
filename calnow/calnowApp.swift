import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @State private var showOnboarding: Bool? = nil
    var body: some View {
        Group {
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
        .task {
            showOnboarding = profiles.isEmpty
        }
    }
}

@main
struct CalNowApp: App {
    @StateObject private var healthKitManageer = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: UserProfile.self)
        .environmentObject(healthKitManageer)
    }
}
