//
//  EnergyBarChartView.swift
//  calnow
//
//  Created by Артем Денисов on 09.12.2025.
//


import SwiftUI
import Charts
import HealthKitDataService

struct DetailChartView: View {
    let points: [any EnergyPoint]
    let average: Int
    let showAverage: Bool
    let unit: Calendar.Component
    @State private var selectedPoint: (any EnergyPoint)?
    
    @State private var tooltipSize: CGSize = .zero
    
    var body: some View {
        Chart {
            // Вертикальная линия для выбранного дня
            if let selectedPoint {
                RuleMark(
                    x: .value("Дата", selectedPoint.date, unit: unit)
                )
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
            
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                BarMark(
                    x: .value("Дата", point.date, unit: unit),
                    y: .value("Ккал", point.value)
                )
                .foregroundStyle(showAverage ? AnyShapeStyle(.ultraThinMaterial) : (isSelected(point) ? AnyShapeStyle(Color.surfChartGradient) : AnyShapeStyle(Color.surfChartGradient.opacity(0.3))))
            }
            
            if showAverage {
                RuleMark(
                    y: .value("Среднее", average)
                )
                .foregroundStyle(.appSurfCoral)
                .annotation(position: .top) {
                    Text("\(Int(average)) ккал/день")
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                let overlaySize = geo.size
                
                ZStack{
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let location = value.location
                                    
                                    if let date: Date = proxy.value(atX: location.x) {
                                        
                                        let periodStart = getPeriodStart(for: date, unit: unit)

                                        // 3) ищем точку с таким бакетом (или ближайшую)
                                        selectedPoint = nearestPoint(in: points, to: periodStart, unit: unit)
                                    }
                                }
                            
                            
                        )
                    
                    if let selectedPoint,
                       let plotFrame = proxy.plotFrame,
                       let xPos = proxy.position(
                        forX: selectedPoint.date
                       ) {
                        
                        let frame = geo[plotFrame]
                        // x внутри overlay (учитываем отступ plotFrame)
                        let tooltipX = xPos + frame.origin.x
                        // y чуть выше верхней границы plotFrame
                        let tooltipY = frame.origin.y
                        
                        
                        let halfW = tooltipSize.width / 2
                        let halfH = tooltipSize.height / 2
                        
                        // Зажимаем по горизонтали/вертикали
                        let clampedX = min(max(tooltipX, halfW), overlaySize.width  - halfW)
                        let clampedY = min(max(tooltipY, halfH), overlaySize.height - halfH)
                        
                        ZStack {
                            // 1) Невидимый тултип — только для измерения
                            //TODO: do it better
                            tooltip(for: selectedPoint)
                                .opacity(0)
                                .background(
                                    GeometryReader { tooltipGeo in
                                        Color.clear
                                            .onAppear {
                                                tooltipSize = tooltipGeo.size
                                            }
                                            .onChange(of: tooltipGeo.size) { _, newSize in
                                                tooltipSize = newSize
                                            }
                                    }
                                )

                            // 2) Видимый тултип с правильной позицией
                            if tooltipSize != .zero {
                                tooltip(for: selectedPoint)
                                    .position(x: clampedX, y: clampedY)
                            }
                        }
                    }
                }
            }
            .onChange(of: points.count) { _ , _ in
                selectedPoint = nil
            }
        }
    }
    
    func getPeriodStart(for date: Date, unit: Calendar.Component, calendar: Calendar = .current) -> Date {
        switch unit {
        case .day:
            return calendar.startOfDay(for: date)

//        case .weekOfYear:
//            // начало недели с учётом локали
//            return calendar.dateInterval(of: .weekOfYear, for: date)!.start

        case .month:
            return calendar.startOfMonth(for: date)

        default:
            // на случай, если ты используешь другие компоненты
            return calendar.startOfDay(for: date)
        }
    }
    
    func nearestPoint(in points: [any EnergyPoint], to periodStart: Date, unit: Calendar.Component, calendar: Calendar = .current) -> (any EnergyPoint)? {
        guard !points.isEmpty else { return nil }

        // Быстрый путь: точное совпадение бакета
        if let exactPoint = points.first(where: { $0.date == periodStart }) {
            return exactPoint
        }

        // Fallback: ближайшая по времени (в секундах)
        return points.min(by: {
            abs($0.date.timeIntervalSince(periodStart)) < abs($1.date.timeIntervalSince(periodStart))
        })
    }
    
    func isSelected(_ point: any EnergyPoint) -> Bool {
        guard let selectedPoint else { return false }
        // Сравниваем по дате с нужной гранулярностью
        let cal = Calendar.autoupdatingCurrent
        return cal.isDate(point.date, equalTo: selectedPoint.date, toGranularity: unit)
    }
    
    @ViewBuilder
    private func tooltip(for point: any EnergyPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Среднее")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(
                    Int(point.average),
                    format: .number.grouping(.automatic) // 2 163
                )
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                
                Text("ккал/день")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(
                point.date,
                format: .dateTime
                    .day()
                    .month(.abbreviated)
                    .year()
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial) // на тёмной будет почти как чёрный
        )
    }
}

private let previewEnergyPoints: [DailyEnergyPoint] = {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    
    return (0..<7).compactMap { offset in
        guard let date = calendar.date(byAdding: .day, value: -6 + Int(offset), to: today) else {
            return DailyEnergyPoint(dayStart: Date(), kcal: 0)
        }
        let base: Double = 2200
        let delta = Double(Int.random(in: -300...300))
        return DailyEnergyPoint(dayStart: date, kcal: base + delta)
    }
}()

#Preview("Detail") {
    DetailChartView(points: previewEnergyPoints, average: 1800, showAverage: true, unit: .day)
        .frame(height: 300)
        .padding()
        .appBackground()
}
