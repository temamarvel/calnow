//
//  DetailsChartView.swift
//  calnow
//
//  Created by Artem Denisov on 09.12.2025.
//

import SwiftUI
import HealthKitDataService
internal import HealthKit
import Charts

struct DetailsView: View {
    @State private var period: PredefinedDateInterval = .last7Days
    @State private var basalPoints: [any EnergyPoint] = []
    @State private var activePoints: [any EnergyPoint] = []
    @State private var totalPoints: [any EnergyPoint] = []
    
    @Environment(\.healthDataService) private var healthKitService
    
    private func loadData() async {
        do {
            let basalDict = try await healthKitService.fetchEnergySums(for: .basalEnergyBurned, in: period.daysInterval, unit: getChartUnit())
            basalPoints = basalDict.map { DailyEnergyPoint(date: $0.key, kcal: $0.value) }.sorted { $0.date < $1.date }
            
            let activeDict = try await healthKitService.fetchEnergySums(for: .activeEnergyBurned, in: period.daysInterval, unit: getChartUnit())
            activePoints = activeDict.map { DailyEnergyPoint(date: $0.key, kcal: $0.value) }.sorted { $0.date < $1.date }
            
            let totalDict = basalDict.merging(activeDict) { basal, active in
                basal + active
            }
            
            totalPoints = totalDict
                .map { DailyEnergyPoint(date: $0.key, kcal: $0.value) }
                .sorted { $0.date < $1.date }
            
        } catch {
            print("Ошибка загрузки: \(error)")
        }
    }
    
    private func getChartUnit() -> Calendar.Component {
        switch period {
            case .last7Days: return .day
            case .last30Days: return .day
            case .last180Days: return .month
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
            
            DetailChartView(points: totalPoints, unit: getChartUnit())
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

#Preview("Chart") {
    DetailsView()
        .environment(\.healthDataService, MockHealthDataService())
}
