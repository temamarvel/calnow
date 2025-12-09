//
//  DetailsChartView.swift
//  calnow
//
//  Created by Artem Denisov on 09.12.2025.
//

import SwiftUI
import HealthKitDataService
internal import HealthKit

struct DetailsChartView: View {
    @State private var period: PredefinedDateInterval = .last7Days
    @State private var basalPoints: [EnergyPoint] = []
    @State private var activePoints: [EnergyPoint] = []
    @State private var totalPoints: [EnergyPoint] = []
    
    @Environment(\.healthDataService) private var healthKitService
    
    private func loadData() async {
        do {
            let basalDict = try await healthKitService.fetchEnergyDailySums(for: .basalEnergyBurned, in: period.daysInterval)
            basalPoints = basalDict.map { EnergyPoint(date: $0.key, kcal: $0.value) }.sorted { $0.date < $1.date }
            
            let activeDict = try await healthKitService.fetchEnergyDailySums(for: .activeEnergyBurned, in: period.daysInterval)
            activePoints = activeDict.map { EnergyPoint(date: $0.key, kcal: $0.value) }.sorted { $0.date < $1.date }
            
            let totalDict = basalDict.merging(activeDict) { basal, active in
                basal + active
            }

            totalPoints = totalDict
                .map { EnergyPoint(date: $0.key, kcal: $0.value) }
                .sorted { $0.date < $1.date }
            
        } catch {
            print("Ошибка загрузки: \(error)")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Энергозатраты, ккал/день")
                    .font(.headline)
                Spacer()
            }
            
            Picker("Период", selection: $period) {
                ForEach(PredefinedDateInterval.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
    
            //TODO: impl charts
        }
        .padding()
        .task {
            await loadData()
        }
        .onChange(of: period) { old, new in
            Task { await loadData() }
        }
    }
}
