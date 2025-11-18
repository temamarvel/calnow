import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @State private var showOnboarding = false
    var body: some View {
        Group{
            if showOnboarding {
                OnboardingMainView(){
                    showOnboarding = false
                }
            } else {
                DashboardRootContainer() // ⬅️ теперь сюда
            }
        }
        .task {
            showOnboarding = !profiles.isEmpty
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
