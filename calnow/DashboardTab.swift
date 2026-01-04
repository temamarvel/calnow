//
//  DashboardTab.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
import SwiftData

enum DashboardTab : Hashable {
    case main, charts
}

struct DashboardRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var tab: DashboardTab = .main
    
    var body: some View {
        TabView(selection: $tab) {
            MainDashboardView()
                .tag(DashboardTab.main)
                .tabItem {
                    Label("Dashboard", systemImage: "flame")
                }
            
            DetailsView()
                .tag(DashboardTab.charts)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis.ascending")
                }
        }
        .onChange(of: scenePhase) { old, phase in
            if phase == .inactive {
                tab = .main
            }
        }
    }
}

struct DashboardTabPreviewWrapper: View {
    let container: ModelContainer
    
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
        DashboardRootView()
            .modelContainer(container)
    }
}

#Preview("Dashboard tabs") {
    DashboardTabPreviewWrapper()
}
