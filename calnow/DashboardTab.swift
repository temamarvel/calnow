//
//  DashboardTab.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
import SwiftData
import HealthKitDataService

enum DashboardTab { case main, charts }

struct DashboardRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var tab: DashboardTab = .main

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .main:
                    MainDashboardView()
                case .charts:
                    DetailsView()
                }
            }
            .onChange(of: scenePhase) { old, phase in
                if phase == .inactive {
                    tab = .main
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        tab = .main
                    } label: {
                        Label("Текущие", systemImage: "gauge.with.dots.needle.67percent")
                            .fontWeight(tab == .main ? .semibold : .regular)
                    }

                    Spacer()

                    Button {
                        tab = .charts
                    } label: {
                        Label("Графики", systemImage: "chart.line.uptrend.:")
                            .fontWeight(tab == .charts ? .semibold : .regular)
                    }
                }
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
