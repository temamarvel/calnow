//
//  ChartsPeriod.swift
//  calnow
//
//  Created by Артем Денисов on 10.11.2025.
//


import SwiftUI
internal import Combine

enum ChartsPeriod: String, CaseIterable, Identifiable {
    case week = "Неделя"
    case month = "Месяц"
    case halfYear = "Полгода"
    case year = "Год"
    var id: String { rawValue }

    func interval(now: Date = .now) -> DateInterval {
        let cal = Calendar.current
        switch self {
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now))!
            return DateInterval(start: start, end: now)
        case .month:
            let start = cal.date(byAdding: .month, value: -1, to: now)!
            return DateInterval(start: cal.startOfDay(for: start), end: now)
        case .halfYear:
            let start = cal.date(byAdding: .month, value: -6, to: now)!
            return DateInterval(start: cal.startOfDay(for: start), end: now)
        case .year:
            let start = cal.date(byAdding: .year, value: -1, to: now)!
            return DateInterval(start: cal.startOfDay(for: start), end: now)
        }
    }
}

struct DayEnergyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let activeKcal: Double
    let basalKcal: Double
}

