//
//  DashboardTab.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
import SwiftData

enum DashboardTab { case current, charts }

struct DashboardRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tab: DashboardTab = .current

    // VM’ки вкладок
    @StateObject private var currentVM = MainDashboardViewModel()
    @StateObject private var chartsVM  = EnergyChartsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .current:
                    MainDashboardView()
                case .charts:
                    EnergyChartsView(vm: chartsVM)
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
                        Label("Графики", systemImage: "chart.line.uptrend.xyaxis")
                            .fontWeight(tab == .charts ? .semibold : .regular)
                    }
                }
            }
            .onAppear {
                // лениво подгрузим данные
                if currentVM.profile == nil {
                    currentVM.onAppear(context: modelContext)
                }
                if chartsVM.series.isEmpty {
                    chartsVM.onAppear()
                }
            }
        }
    }
}
