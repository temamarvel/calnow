//
//  DashboardTab.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
import SwiftData

enum DashboardTab { case current, charts }


struct DashboardRootContainer: View {
    @EnvironmentObject private var hk : HealthKitManager
    var body: some View {
        DashboardRootView(health: hk) // ← передаём зависимость
    }
}

struct DashboardRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tab: DashboardTab = .current
    
    init(health: HealthKitServicing) { }

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .current:
                    MainDashboardView()
                case .charts:
                    BasalEnergyChartView()
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
