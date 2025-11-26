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

struct ActiveEnergyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let activeKcal: Double
}

struct TotalEnergyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalKcal: Double
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
    @State private var basalPoints: [BasalEnergyPoint] = []
    @State private var activePoints: [ActiveEnergyPoint] = []
    @State private var showAverageLine: Bool = true
    
    
    @EnvironmentObject private var healthKitManager: HealthKitManager

    private func loadData() async {
        do {
            basalPoints = try await healthKitManager.basalEnergyPoints(for: period)
            activePoints = try await healthKitManager.activeEnergyPoints(for: period)
        } catch {
            // обработка ошибки, можно добавить стейт errorMessage
            print("Ошибка загрузки: \(error)")
        }
    }

    // вычисляем среднее по текущим точкам
    private var averageBasal: Double {
        guard !basalPoints.isEmpty else { return 0 }
        let sum = basalPoints.reduce(0) { $0 + $1.basalKcal }
        return sum / Double(basalPoints.count)
    }
    
    private var totalPoints: [TotalEnergyPoint] {
        let calendar = Calendar.current

        // 1. Приводим даты к startOfDay, чтобы не разъезжались по времени
        let basalByDate = Dictionary(
            uniqueKeysWithValues: basalPoints.map { point in
                (calendar.startOfDay(for: point.date), point.basalKcal)
            }
        )

        let activeByDate = Dictionary(
            uniqueKeysWithValues: activePoints.map { point in
                (calendar.startOfDay(for: point.date), point.activeKcal)
            }
        )

        // 2. Собираем полный набор дат, которые есть хотя бы в одной серии
        let allDates = Set(basalByDate.keys).union(activeByDate.keys)

        // 3. Для каждой даты считаем сумму
        let result: [TotalEnergyPoint] = allDates.map { date in
            let basal = basalByDate[date] ?? 0
            let active = activeByDate[date] ?? 0
            return TotalEnergyPoint(date: date, totalKcal: basal + active)
        }

        // 4. Возвращаем отсортированным по дате
        return result.sorted { $0.date < $1.date }
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
                ForEach(basalPoints) { point in
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
                }.foregroundStyle(by: .value("Серия", "Базальный"))
                
                ForEach(activePoints) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Активный", point.activeKcal)
                    )
                    // интерполяция: сглаженная линия вместо "ломаной"
                    .interpolationMethod(.catmullRom)

                    // Можно добавить точки на графике
                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value("Активный", point.activeKcal)
                    )
                    .symbolSize(20)
                }.foregroundStyle(by: .value("Серия", "Активный"))
                
                ForEach(totalPoints) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value("Активный", point.totalKcal)
                    )
                    // интерполяция: сглаженная линия вместо "ломаной"
                    .interpolationMethod(.catmullRom)

                    // Можно добавить точки на графике
                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value("Активный", point.totalKcal)
                    )
                    .symbolSize(20)
                }.foregroundStyle(by: .value("Серия", "Итоговый"))

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
            .chartForegroundStyleScale([
                "Базальный": Color.blue,
                "Активный": Color.orange,
                "Итоговый": Color.purple
            ])
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
