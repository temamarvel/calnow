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

struct DailyEnergyChartView: View {
    let basalPoints: [BasalEnergyPoint]
    let activePoints: [ActiveEnergyPoint]
    let totalPoints: [TotalEnergyPoint]
    
    var body: some View {
        Chart {
            // Базальный
            ForEach(basalPoints) { point in
                LineMark(
                    x: .value("Дата", point.date),
                    y: .value("Ккал/день", point.basalKcal)
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Дата", point.date),
                    y: .value("Ккал/день", point.basalKcal)
                )
                .symbolSize(20)
            }
            .foregroundStyle(by: .value("Серия", "Базальный"))
            
            // Активный
            ForEach(activePoints) { point in
                LineMark(
                    x: .value("Дата", point.date),
                    y: .value("Ккал/день", point.activeKcal)
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Дата", point.date),
                    y: .value("Ккал/день", point.activeKcal)
                )
                .symbolSize(20)
            }
            .foregroundStyle(by: .value("Серия", "Активный"))
            
            // Итоговый
            ForEach(totalPoints) { point in
                LineMark(
                    x: .value("Дата", point.date),
                    y: .value("Ккал/день", point.totalKcal)
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Дата", point.date),
                    y: .value("Ккал/день", point.totalKcal)
                )
                .symbolSize(20)
            }
            .foregroundStyle(by: .value("Серия", "Итоговый"))
        }
    }
}

struct AverageEnergyChartView: View {
    let averageBasal: Double
    let averageActive: Double
    let averageTotal: Double
    let xDomain: ClosedRange<Date>?
    
    var body: some View {
        Chart {
            
            
            // Базальный
            if averageBasal > 0, let domain = xDomain {
                let bandDates = [domain.lowerBound, domain.upperBound]
                
                ForEach(bandDates, id: \.self) { date in
                    AreaMark(
                        x: .value("Дата", date),
                        yStart: .value("Нижняя граница", 0),
                        yEnd: .value("Среднее", averageBasal)
                    )
                }
                .foregroundStyle(Color.blue.opacity(0.15))
                
                RuleMark(
                    y: .value("Среднее базальный", averageBasal)
                )
                .foregroundStyle(by: .value("Серия", "Базальный"))
                .annotation(position: .top) {
                    Text("Базальный: \(Int(averageBasal)) ккал/день")
                        .font(.caption)
                        .padding(4)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Активный
            if averageActive > 0, let domain = xDomain{
//                AreaMark(
//                    x: .value("Дата", domain.lowerBound),
//                    x2: .value("Дата", domain.upperBound),
//                    yStart: .value("Нижняя граница", 0),
//                    yEnd: .value("Среднее", averageActive)
//                )
//                .foregroundStyle(Color.orange.opacity(0.15))
                
                RuleMark(
                    y: .value("Среднее активный", averageActive)
                )
                .foregroundStyle(by: .value("Серия", "Активный"))
                .annotation(position: .top) {
                    Text("Активный: \(Int(averageActive)) ккал/день")
                        .font(.caption)
                        .padding(4)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Итоговый
            if averageTotal > 0, let domain = xDomain {
//                AreaMark(
//                    x: .value("Дата", domain.lowerBound),
//                    x2: .value("Дата", domain.upperBound),
//                    yStart: .value("Нижняя граница", 0),
//                    yEnd: .value("Среднее", averageTotal)
//                )
//                .foregroundStyle(Color.purple.opacity(0.15))
                
                RuleMark(
                    y: .value("Среднее всего", averageTotal)
                )
                .foregroundStyle(by: .value("Серия", "Итоговый"))
                .annotation(position: .top) {
                    Text("Итого: \(Int(averageTotal)) ккал/день")
                        .font(.caption)
                        .padding(4)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

struct EnergyChartView: View {
    let basalPoints: [BasalEnergyPoint]
    let activePoints: [ActiveEnergyPoint]
    let totalPoints: [TotalEnergyPoint]
    let showDailyChart: Bool
    
    // MARK: - Aggregates
    
    private var averageBasal: Double {
        guard !basalPoints.isEmpty else { return 0 }
        let sum = basalPoints.reduce(0) { $0 + $1.basalKcal }
        return sum / Double(basalPoints.count)
    }
    
    private var averageActive: Double {
        guard !activePoints.isEmpty else { return 0 }
        let sum = activePoints.reduce(0) { $0 + $1.activeKcal }
        return sum / Double(activePoints.count)
    }
    
    private var averageTotal: Double {
        guard !totalPoints.isEmpty else { return 0 }
        let sum = totalPoints.reduce(0) { $0 + $1.totalKcal }
        return sum / Double(totalPoints.count)
    }
    
    private var xDomain: ClosedRange<Date>? {
        guard let first = totalPoints.first?.date,
              let last  = totalPoints.last?.date else { return nil }
        return first...last
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if showDailyChart {
                DailyEnergyChartView(
                    basalPoints: basalPoints,
                    activePoints: activePoints,
                    totalPoints: totalPoints
                )
            } else {
                AverageEnergyChartView(
                    averageBasal: averageBasal,
                    averageActive: averageActive,
                    averageTotal: averageTotal,
                    xDomain: xDomain
                )
            }
        }
        .chartForegroundStyleScale([
            "Базальный": Color.blue,
            "Активный": Color.orange,
            "Итоговый": Color.purple
        ])
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .chartYAxis {
            AxisMarks()
        }
        .frame(height: 240)
    }
}

struct BasalEnergyChartView: View {
    @State private var period: BasalChartPeriod = .week
    @State private var basalPoints: [BasalEnergyPoint] = []
    @State private var activePoints: [ActiveEnergyPoint] = []
    
    @State private var showDailyChart: Bool = false
    
    @EnvironmentObject private var healthKitManager: HealthKitManager
    
    private func loadData() async {
        do {
            basalPoints = try await healthKitManager.basalEnergyPoints(for: period)
            activePoints = try await healthKitManager.activeEnergyPoints(for: period)
        } catch {
            print("Ошибка загрузки: \(error)")
        }
    }
    
    // Общие totalPoints — используем тут и отдаём в чарт
    private var totalPoints: [TotalEnergyPoint] {
        let calendar = Calendar.current
        
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
        
        let allDates = Set(basalByDate.keys).union(activeByDate.keys)
        
        let result: [TotalEnergyPoint] = allDates.map { date in
            let basal = basalByDate[date] ?? 0
            let active = activeByDate[date] ?? 0
            return TotalEnergyPoint(date: date, totalKcal: basal + active)
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    // Сумма за текущую неделю по тоталу
    private var weekTotalKcal: Double {
        let calendar = Calendar.current
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }
        
        return totalPoints
            .filter { point in
                let day = calendar.startOfDay(for: point.date)
                return weekInterval.contains(day)
            }
            .reduce(0) { $0 + $1.totalKcal }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Энергозатраты, ккал/день")
                    .font(.headline)
                Spacer()
            }
            
            Picker("Период", selection: $period) {
                ForEach(BasalChartPeriod.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            Toggle("Показывать детализацию по дням", isOn: $showDailyChart)
                .font(.subheadline)
            
            // 🔻 Вместо Chart { ... } просто используем дочерний чарт
            EnergyChartView(
                basalPoints: basalPoints,
                activePoints: activePoints,
                totalPoints: totalPoints,
                showDailyChart: showDailyChart
            )
            
            if weekTotalKcal > 0 {
                Text("С начала недели: \(Int(weekTotalKcal)) ккал")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .task {
            await loadData()
        }
        .onChange(of: period) { _ in
            Task { await loadData() }
        }
    }
}
