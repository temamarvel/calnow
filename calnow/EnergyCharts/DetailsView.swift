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
import SwiftData

struct DetailsView: View {
    @State private var period: PredefinedDateInterval = .last7Days
    @State private var basalPoints: [any EnergyPoint] = []
    @State private var activePoints: [any EnergyPoint] = []
    @State private var totalPoints: [any EnergyPoint] = []
    
    @Query private var profiles: [UserProfile]
    
    // Для простоты берём первый профиль
    private var profile: UserProfile? { profiles.first }
    
    private var bmr: Double {
        profile?.bmr ?? 0   // имя свойства подставь своё
    }
    
    @Environment(\.healthDataService) private var healthKitService
    
    var averageTotal: Int {
        guard !totalPoints.isEmpty else {
            return 0
        }
        
        return Int(totalPoints.map(\.average).reduce(0, +) / Double(totalPoints.count))
    }
    
    
    
    private func loadData(by aggregate: AggregatePeriod, makePoint: (Date, Double) -> any EnergyPoint
    ) async throws {
        let basalDict = try await healthKitService.fetchEnergySums(
            for: .basalEnergyBurned,
            in: period.daysInterval,
            by: aggregate
        )
        
        let activeDict = try await healthKitService.fetchEnergySums(
            for: .activeEnergyBurned,
            in: period.daysInterval,
            by: aggregate
        )
        
        let totalDict = basalDict.merging(activeDict, uniquingKeysWith: +)
        
        basalPoints = basalDict
            .map { makePoint($0.key, $0.value) }
            .sorted { $0.date < $1.date }
        
        activePoints = activeDict
            .map { makePoint($0.key, $0.value) }
            .sorted { $0.date < $1.date }
        
        totalPoints = totalDict
            .map { makePoint($0.key, $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private func loadData() async {
        do {
            let aggregate = getAggregatePeriod()
            
            switch aggregate {
            case .day:
                try await loadData(
                    by: aggregate,
                    makePoint: { date, value in
                        DailyEnergyPoint(dayStart: date, kcal: value)
                    }
                )
                
            case .month:
                try await loadData(
                    by: aggregate,
                    makePoint: { date, value in
                        MonthlyEnergyPoint(monthStart: date, kcal: value)
                    }
                )
                
            default:
                try await loadData(
                    by: aggregate,
                    makePoint: { date, value in
                        DailyEnergyPoint(dayStart: date, kcal: value)
                    }
                )
            }
            
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
    
    private func getAggregatePeriod() -> AggregatePeriod {
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Среднее")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(
                        averageTotal,
                        format: .number.grouping(.automatic) // 2 163
                    )
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    
                    Text("ккал/день")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                let dateRange: Range<Date> = period.daysInterval.start..<period.daysInterval.end
                
                Text(
                    dateRange,
                    format: .interval
                        .day()
                        .month(.abbreviated)
                        .year()
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial) // на тёмной будет почти как чёрный
            )
            
            
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
