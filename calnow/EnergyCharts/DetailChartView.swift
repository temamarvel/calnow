//
//  EnergyBarChartView.swift
//  calnow
//
//  Created by Артем Денисов on 09.12.2025.
//


import SwiftUI
import Charts

struct DetailChartView: View {
    let points: [any EnergyPoint]
    let unit: Calendar.Component
    @State private var selectedPoint: (any EnergyPoint)?
    
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
                .foregroundStyle(isSelected(point) ? .orange : .blue)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                ZStack{
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let location = value.location
                                    
                                    if let date: Date = proxy.value(atX: location.x) {
                                        if let nearest = points.min(by: {
                                            abs($0.date.timeIntervalSince(date)) <
                                                abs($1.date.timeIntervalSince(date))
                                        }) {
                                            selectedPoint = nearest
                                        }
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
                        let tooltipY = frame.origin.y - 12
                        
                        tooltip(for: selectedPoint)
                            //.fixedSize()          // пусть сам подбирает размер
                            .position(x: tooltipX, y: max(tooltipY, 0 + 32)) // чтобы не уехал за край
                    }
                }
            }
        }
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
            Text("ВСЕГО")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(
                    Int(point.value),
                    format: .number.grouping(.automatic) // 2 163
                )
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                
                Text("ккал")
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
    DetailChartView(points: previewEnergyPoints, unit: .day)
            .frame(height: 300)
            .padding()
}
