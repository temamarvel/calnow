import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    var body: some View {
        if profiles.first != nil {
            DashboardRootContainer() // ⬅️ теперь сюда
        } else {
            OnboardingContainer()
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
