//
//  DashboardTab.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
import SwiftData
import HealthKitDataService

enum DashboardTab { case current, charts }


struct DashboardRootContainer: View {
    @Environment(\.healthDataService) private var healthKitService
    var body: some View {
        DashboardRootView(health: healthKitService) // ← передаём зависимость
    }
}

struct DashboardRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tab: DashboardTab = .current
    
    init(health: HealthDataService) { }

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .current:
                    MainDashboardView()
                case .charts:
                    DetailsChartView()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        tab = .current
                    } label: {
                        Label("Текущие", systemImage: "gauge.with.dots.needle.67percent")
                            .fontWeight(tab == .current ? .semibold : .regular)
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
