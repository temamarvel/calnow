//
//  BasalEnergyChartView.swift
//  calnow
//
//  Created by Artem Denisov on 24.11.2025.
//

import SwiftUI
import Charts

struct BasalEnergyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let basalKcal: Double
}

enum BasalChartPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case halfYear
    case year

    var id: Self { self }

    var title: String {
        switch self {
        case .week:     return "Неделя"
        case .month:    return "Месяц"
        case .halfYear: return "6 мес"
        case .year:     return "Год"
        }
    }

    /// Сколько дней показываем на графике
    var days: Int {
        switch self {
        case .week:     return 7
        case .month:    return 30
        case .halfYear: return 180
        case .year:     return 365
        }
    }
}


struct BasalEnergyChartView: View {
    @State private var period: BasalChartPeriod = .week
    @State private var points: [BasalEnergyPoint] = []
    @State private var showAverageLine: Bool = true
    
    
    @EnvironmentObject private var healthKitManager: HealthKitManager

    private func loadData() async {
        do {
            points = try await healthKitManager.basalEnergyPoints(for: period)
        } catch {
            // обработка ошибки, можно добавить стейт errorMessage
            print("Ошибка загрузки: \(error)")
        }
    }

    // вычисляем среднее по текущим точкам
    private var averageBasal: Double {
        guard !points.isEmpty else { return 0 }
        let sum = points.reduce(0) { $0 + $1.basalKcal }
        return sum / Double(points.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок + период
            HStack {
                Text("Базальный расход, ккал/день")
                    .font(.headline)
                Spacer()
            }

            Picker("Период", selection: $period) {
                ForEach(BasalChartPeriod.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Показывать среднее значение", isOn: $showAverageLine)
                .font(.subheadline)

            Chart {
                // Линейный график по дням
                ForEach(points) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Базальный", point.basalKcal)
                    )
                    // интерполяция: сглаженная линия вместо "ломаной"
                    .interpolationMethod(.catmullRom)

                    // Можно добавить точки на графике
                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value("Базальный", point.basalKcal)
                    )
                    .symbolSize(20)
                }

                // Линия среднего значения
                if showAverageLine && averageBasal > 0 {
                    RuleMark(
                        y: .value("Среднее", averageBasal)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .bottom, alignment: .center) {
                        Text("Среднее \(Int(averageBasal)) ккал")
                            .font(.caption)
                            .padding(4)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .chartXAxis {
                // Ось X по датам, но не слишком плотная
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .chartYAxis {
                AxisMarks()
            }
            .frame(height: 240)
        }
        .padding()
        // при первом показе загружаем данные для выбранного периода
        .task {
            await loadData()
        }
        .onChange(of: period) { _ in
            Task { await loadData() }
        }
    }

//    // MARK: - Временный генератор мок-данных
//
//    private func makeMockData(for period: BasalChartPeriod) -> [BasalEnergyPoint] {
//        let calendar = Calendar.current
//        let today = calendar.startOfDay(for: Date())
//
//        // последние N дней, от старых к новым
//        let days = period.days
//
//        return (0..<days).compactMap { offset in
//            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
//                return nil
//            }
//            // условно базальный расход: вокруг 1700 ккал с шумом ±200
//            let value = 1700 + Double.random(in: -200...200)
//            return BasalEnergyPoint(date: date, basalKcal: value)
//        }
//        .sorted { $0.date < $1.date }
//    }
}
