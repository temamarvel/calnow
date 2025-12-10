import SwiftUI
import HealthKitDataService
import Charts
internal import HealthKit

struct DailyEnergyPoint: EnergyPoint {
    let id = UUID()
    let date: Date
    let kcal: Double
}

protocol EnergyPoint: Identifiable {
    var date: Date { get }
    var kcal: Double { get }   // обобщённое числовое значение (ккал, среднее, сумма и т.п.)
}

//struct DailyEnergyChartView: View {
//    let basalPoints: [EnergyPoint]
//    let activePoints: [EnergyPoint]
//    let totalPoints: [EnergyPoint]
//    
//    @State private var selectedPoint: EnergyPoint?
//    
//    var body: some View {
//        VStack{
//            Chart {
////                // Базальный
////                ForEach(basalPoints) { point in
////                    BarMark(
////                        x: .value("Дата", point.date),
////                        y: .value("Ккал/день", point.kcal)
////                    )
////                    .interpolationMethod(.catmullRom)
////                    
////                    PointMark(
////                        x: .value("Дата", point.date),
////                        y: .value("Ккал/день", point.kcal)
////                    )
////                    .symbolSize(20)
////                }
////                .foregroundStyle(by: .value("Серия", "Базальный"))
//                
////                // Активный
////                ForEach(activePoints) { point in
////                    LineMark(
////                        x: .value("Дата", point.date),
////                        y: .value("Ккал/день", point.kcal)
////                    )
////                    .interpolationMethod(.catmullRom)
////                    
////                    PointMark(
////                        x: .value("Дата", point.date),
////                        y: .value("Ккал/день", point.kcal)
////                    )
////                    .symbolSize(20)
////                }
////                .foregroundStyle(by: .value("Серия", "Активный"))
//                
//                // Итоговый
//                ForEach(totalPoints) { point in
//                    BarMark(
//                        x: .value("Дата", point.date, unit: .day),
//                        y: .value("Ккал/день", point.kcal)
//                    )
//                    .foregroundStyle(selectedPoint?.id == point.id ? .orange : .blue)
//                    //.interpolationMethod(.catmullRom)
//                    
////                    PointMark(
////                        x: .value("Дата", point.date),
////                        y: .value("Ккал/день", point.kcal)
////                    )
////                    .symbolSize(selectedPoint?.id == point.id ? 100 : 20)
//                }
//                //.foregroundStyle(by: .value("Серия", "Итоговый"))
//            }
//            .chartOverlay { proxy in
//                GeometryReader { geo in
//                    // Прозрачный слой, принимающий жесты
//                    Rectangle()
//                        .fill(.clear)
//                        .contentShape(Rectangle())
//                        .gesture(
//                            SpatialTapGesture()
//                                .onEnded { value in
//                                    let location = value.location
//                                    
//                                    // Получаем значение X (дату) на том месте, где тапнули
//                                    if let date: Date = proxy.value(atX: location.x) {
//                                        // Находим ближайшую точку к этой дате
//                                        if let nearest = totalPoints.min(by: {
//                                            abs($0.date.timeIntervalSince(date)) <
//                                                abs($1.date.timeIntervalSince(date))
//                                        }) {
//                                            selectedPoint = nearest
//                                        }
//                                    }
//                                }
//                        )
//                }
//            }
//        }
//        
//        Text("selectedPoint\(selectedPoint)")
//    }
//}
//
//struct AverageEnergyChartView: View {
//    let averageBasal: Double
//    let averageActive: Double
//    let averageTotal: Double
//    let xDomain: ClosedRange<Date>?
//    
//    var body: some View {
//        Chart {
//            
//            
//            // Базальный
//            if averageBasal > 0, let domain = xDomain {
//                let bandDates = [domain.lowerBound, domain.upperBound]
//                
//                ForEach(bandDates, id: \.self) { date in
//                    AreaMark(
//                        x: .value("Дата", date),
//                        yStart: .value("Нижняя граница", 0),
//                        yEnd: .value("Среднее", averageBasal)
//                    )
//                }
//                .foregroundStyle(Color.blue.opacity(0.15))
//                
//                RuleMark(
//                    y: .value("Среднее базальный", averageBasal)
//                )
//                .foregroundStyle(by: .value("Серия", "Базальный"))
//                .annotation(position: .top) {
//                    Text("Базальный: \(Int(averageBasal)) ккал/день")
//                        .font(.caption)
//                        .padding(4)
//                        .background(.thinMaterial)
//                        .clipShape(RoundedRectangle(cornerRadius: 6))
//                }
//            }
//            
//            // Активный
//            if averageActive > 0, let domain = xDomain{
////                AreaMark(
////                    x: .value("Дата", domain.lowerBound),
////                    x2: .value("Дата", domain.upperBound),
////                    yStart: .value("Нижняя граница", 0),
////                    yEnd: .value("Среднее", averageActive)
////                )
////                .foregroundStyle(Color.orange.opacity(0.15))
//                
//                RuleMark(
//                    y: .value("Среднее активный", averageActive)
//                )
//                .foregroundStyle(by: .value("Серия", "Активный"))
//                .annotation(position: .top) {
//                    Text("Активный: \(Int(averageActive)) ккал/день")
//                        .font(.caption)
//                        .padding(4)
//                        .background(.thinMaterial)
//                        .clipShape(RoundedRectangle(cornerRadius: 6))
//                }
//            }
//            
//            // Итоговый
//            if averageTotal > 0, let domain = xDomain {
////                AreaMark(
////                    x: .value("Дата", domain.lowerBound),
////                    x2: .value("Дата", domain.upperBound),
////                    yStart: .value("Нижняя граница", 0),
////                    yEnd: .value("Среднее", averageTotal)
////                )
////                .foregroundStyle(Color.purple.opacity(0.15))
//                
//                RuleMark(
//                    y: .value("Среднее всего", averageTotal)
//                )
//                .foregroundStyle(by: .value("Серия", "Итоговый"))
//                .annotation(position: .top) {
//                    Text("Итого: \(Int(averageTotal)) ккал/день")
//                        .font(.caption)
//                        .padding(4)
//                        .background(.thinMaterial)
//                        .clipShape(RoundedRectangle(cornerRadius: 6))
//                }
//            }
//        }
//    }
//}
//
//struct EnergyChartView: View {
//    let basalPoints: [EnergyPoint]
//    let activePoints: [EnergyPoint]
//    let totalPoints: [EnergyPoint]
//    let showDailyChart: Bool
//    
//    // MARK: - Aggregates
//    
//    private var averageBasal: Double {
//        guard !basalPoints.isEmpty else { return 0 }
//        let sum = basalPoints.reduce(0) { $0 + $1.kcal }
//        return sum / Double(basalPoints.count)
//    }
//    
//    private var averageActive: Double {
//        guard !activePoints.isEmpty else { return 0 }
//        let sum = activePoints.reduce(0) { $0 + $1.kcal }
//        return sum / Double(activePoints.count)
//    }
//    
//    private var averageTotal: Double {
//        guard !totalPoints.isEmpty else { return 0 }
//        let sum = totalPoints.reduce(0) { $0 + $1.kcal }
//        return sum / Double(totalPoints.count)
//    }
//    
//    private var xDomain: ClosedRange<Date>? {
//        guard let first = totalPoints.first?.date,
//              let last  = totalPoints.last?.date else { return nil }
//        return first...last
//    }
//    
//    // MARK: - Body
//    
//    var body: some View {
//        Group {
//            if showDailyChart {
//                DailyEnergyChartView(
//                    basalPoints: basalPoints,
//                    activePoints: activePoints,
//                    totalPoints: totalPoints
//                )
//            } else {
//                AverageEnergyChartView(
//                    averageBasal: averageBasal,
//                    averageActive: averageActive,
//                    averageTotal: averageTotal,
//                    xDomain: xDomain
//                )
//            }
//        }
////        .chartForegroundStyleScale([
////            "Базальный": Color.blue,
////            "Активный": Color.orange,
////            "Итоговый": Color.purple
////        ])
//        .chartXAxis {
//            AxisMarks(values: .automatic(desiredCount: 4))
//        }
//        .chartYAxis {
//            AxisMarks()
//        }
//        .frame(height: 240)
//    }
//}
//
//struct BasalEnergyChartView: View {
//    @State private var period: PredefinedDateInterval = .last7Days
//    @State private var basalPoints: [EnergyPoint] = []
//    @State private var activePoints: [EnergyPoint] = []
//    
//    @State private var showDailyChart: Bool = false
//    
//    @Environment(\.healthDataService) private var healthKitService
//    
//    private func loadData() async {
//        do {
//            let basalDict = try await healthKitService.fetchEnergySums(for: .basalEnergyBurned, in: period.daysInterval, unit: .day)
//            
//                  basalPoints = basalDict.map { EnergyPoint(date: $0.key, kcal: $0.value) }.sorted { $0.date < $1.date }
//            let activeDict = try await healthKitService.fetchEnergySums(for: .activeEnergyBurned, in: period.daysInterval, unit: .day)
//            
//            activePoints = activeDict.map { EnergyPoint(date: $0.key, kcal: $0.value) }.sorted { $0.date < $1.date }
//            
//        } catch {
//            print("Ошибка загрузки: \(error)")
//        }
//    }
//    
//    // Общие totalPoints — используем тут и отдаём в чарт
//    private var totalPoints: [EnergyPoint] {
//        let calendar = Calendar.current
//        
//        let basalByDate = Dictionary(
//            uniqueKeysWithValues: basalPoints.map { point in
//                (calendar.startOfDay(for: point.date), point.kcal)
//            }
//        )
//        
//        let activeByDate = Dictionary(
//            uniqueKeysWithValues: activePoints.map { point in
//                (calendar.startOfDay(for: point.date), point.kcal)
//            }
//        )
//        
//        let allDates = Set(basalByDate.keys).union(activeByDate.keys)
//        
//        let result: [EnergyPoint] = allDates.map { date in
//            let basal = basalByDate[date] ?? 0
//            let active = activeByDate[date] ?? 0
//            return EnergyPoint(date: date, kcal: basal + active)
//        }
//        
//        return result.sorted { $0.date < $1.date }
//    }
//    
//    // Сумма за текущую неделю по тоталу
//    private var weekTotalKcal: Double {
//        let calendar = Calendar.current
//        
//        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
//            return 0
//        }
//        
//        return totalPoints
//            .filter { point in
//                let day = calendar.startOfDay(for: point.date)
//                return weekInterval.contains(day)
//            }
//            .reduce(0) { $0 + $1.kcal }
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Text("Энергозатраты, ккал/день")
//                    .font(.headline)
//                Spacer()
//            }
//            
//            Picker("Период", selection: $period) {
//                ForEach(PredefinedDateInterval.allCases) { range in
//                    Text(range.title).tag(range)
//                }
//            }
//            .pickerStyle(.segmented)
//            
//            Toggle("Показывать детализацию по дням", isOn: $showDailyChart)
//                .font(.subheadline)
//            
//            // 🔻 Вместо Chart { ... } просто используем дочерний чарт
//            EnergyChartView(
//                basalPoints: basalPoints,
//                activePoints: activePoints,
//                totalPoints: totalPoints,
//                showDailyChart: showDailyChart
//            )
//            
//            if weekTotalKcal > 0 {
//                Text("С начала недели: \(Int(weekTotalKcal)) ккал")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .padding()
//        .task {
//            await loadData()
//        }
//        .onChange(of: period) { _ in
//            Task { await loadData() }
//        }
//    }
//}
//
//#Preview("Chart") {
//    BasalEnergyChartView()
//        .environment(\.healthDataService, MockHealthDataService())
//}
