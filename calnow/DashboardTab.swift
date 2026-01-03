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


struct DashboardRootContainer: View {
    @Environment(\.healthDataService) private var healthKitService
    var body: some View {
        DashboardRootView(health: healthKitService) // ← передаём зависимость
    }
}

struct DashboardRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var tab: DashboardTab = .main
    
    init(health: HealthDataService) { }

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
