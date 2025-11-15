//
//  EnergyChartsView.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
import Charts

struct EnergyChartsView: View {
    @StateObject var vm: EnergyChartsViewModel

    var body: some View {
        List {
            Section {
                Picker("Период", selection: $vm.period) {
                    ForEach(ChartsPeriod.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: vm.period) { _, _ in vm.refresh() }
            }

            Section("Энергия по дням") {
                if vm.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if vm.series.isEmpty {
                    Text("Нет данных за выбранный период")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(vm.series) { point in
                        BarMark(
                            x: .value("Дата", point.date, unit: .day),
                            y: .value("Активная", point.activeKcal)
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                        BarMark(
                            x: .value("Дата", point.date, unit: .day),
                            y: .value("Базальная", point.basalKcal)
                        )
                        .foregroundStyle(.orange.opacity(0.6))
                        .position(by: .value("Категория", "Basal"))
                    }
                    .frame(height: 240)

                    // Сумма за период
                    let totalActive = Int(vm.series.reduce(0) { $0 + $1.activeKcal })
                    let totalBasal  = Int(vm.series.reduce(0) { $0 + $1.basalKcal })
                    let totalAll    = totalActive + totalBasal

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Итого за период:")
                            .font(.headline)
                        HStack {
                            Text("Активная"); Spacer(); Text("\(totalActive) ккал").fontWeight(.semibold)
                        }
                        HStack {
                            Text("Базальная"); Spacer(); Text("\(totalBasal) ккал").fontWeight(.semibold)
                        }
                        Divider()
                        HStack {
                            Text("Всего"); Spacer(); Text("\(totalAll) ккал").fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Графики")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("Ошибка", isPresented: Binding(
            get: { vm.alertMessage != nil },
            set: { if !$0 { vm.alertMessage = nil } }
        )) { Button("OK", role: .cancel) {} } message: {
            Text(vm.alertMessage ?? "")
        }
    }
}