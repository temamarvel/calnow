import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]
    
    var body: some View {
        if profiles.first != nil {
            MainDashboardView()
        } else {
            OnboardingView()
        }
    }
}

@main
struct CalNowApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: UserProfile.self)
    }
}
