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

struct DetailsChartView: View {
    @State private var period: PredefinedDateInterval = .last7Days
    @State private var basalPoints: [EnergyPoint] = []
    @State private var activePoints: [EnergyPoint] = []
    @State private var totalPoints: [EnergyPoint] = []
    
    @State private var selectedPoint: EnergyPoint?
    
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
    
            Chart {
                
                
                // Итоговый
                ForEach(totalPoints) { point in
                    BarMark(
                        x: .value("Дата", point.date, unit: .day),
                        y: .value("Ккал/день", point.kcal)
                    )
                    .foregroundStyle(selectedPoint?.id == point.id ? .orange : .blue)
                    //.interpolationMethod(.catmullRom)
                    
                    //                    PointMark(
                    //                        x: .value("Дата", point.date),
                    //                        y: .value("Ккал/день", point.kcal)
                    //                    )
                    //                    .symbolSize(selectedPoint?.id == point.id ? 100 : 20)
                }
                //.foregroundStyle(by: .value("Серия", "Итоговый"))
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    // Прозрачный слой, принимающий жесты
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let location = value.location
                                    
                                    // Получаем значение X (дату) на том месте, где тапнули
                                    if let date: Date = proxy.value(atX: location.x) {
                                        // Находим ближайшую точку к этой дате
                                        if let nearest = totalPoints.min(by: {
                                            abs($0.date.timeIntervalSince(date)) <
                                                abs($1.date.timeIntervalSince(date))
                                        }) {
                                            selectedPoint = nearest
                                        }
                                    }
                                }
                        )
                }
            }
        
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
    DetailsChartView()
        .environment(\.healthDataService, MockHealthDataService())
}
