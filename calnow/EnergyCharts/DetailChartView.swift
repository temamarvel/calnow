//
//  EnergyBarChartView.swift
//  calnow
//
//  Created by Артем Денисов on 09.12.2025.
//


import SwiftUI
import Charts

struct DetailChartView: View {
    let points: [EnergyPoint]
    let unit: Calendar.Component = .day
    @State private var selectedPoint: EnergyPoint?
    
    var body: some View {
        Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value("Дата", point.date, unit: unit),
                    y: .value("Ккал/день", point.kcal)
                )
                .foregroundStyle(selectedPoint?.id == point.id ? .orange : .blue)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
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
            }
        }
    }
}

private let previewEnergyPoints: [EnergyPoint] = {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    
    return (0..<7).compactMap { offset in
        guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else {
            return nil
        }
        let base: Double = 2200
        let delta = Double(Int.random(in: -300...300))
        return EnergyPoint(date: date, kcal: base + delta)
    }
}()

#Preview("Detail") {
        DetailChartView(points: previewEnergyPoints)
            .frame(height: 300)
            .padding()
}
