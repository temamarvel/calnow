//
//  DaySequence.swift
//  calnow
//
//  Created by Artem Denisov on 24.11.2025.
//


import Foundation
import HealthKitDataService

/// Ленивый Sequence по началу суток в интервале
struct DaySequence: Sequence, IteratorProtocol {
    private let calendar: Calendar
    private let end: Date
    private var current: Date?

    init(start: Date, end: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        // приводим оба конца к началу суток
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        self.current = startDay
        self.end = endDay
    }

    mutating func next() -> Date? {
        guard let date = current, date < end else {
            return nil
        }

        // подготовим значение для следующего вызова next()
        current = calendar.date(byAdding: .day, value: 1, to: date)
        return date
    }
}

struct MonthSequence: Sequence, IteratorProtocol {
    private let calendar: Calendar
    private let end: Date
    private var current: Date?

    init(start: Date, end: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        // приводим оба конца к началу суток
        let startDay = calendar.startOfMonth(for: start)
        let endDay = calendar.startOfMonth(for: end)

        self.current = startDay
        self.end = endDay
    }

    mutating func next() -> Date? {
        guard let date = current, date < end else {
            return nil
        }

        // подготовим значение для следующего вызова next()
        current = calendar.date(byAdding: .month, value: 1, to: date)
        return date
    }
}

extension DateInterval {
    /// Ленивый итератор по дням интервала (начало суток каждого дня)
    func daysSequence(calendar: Calendar = .current) -> DaySequence {
        DaySequence(start: start, end: end, calendar: calendar)
    }
    
    func monthsSequence(calendar: Calendar = .current) -> MonthSequence {
        MonthSequence(start: start, end: end, calendar: calendar)
    }
    
    func periods(by aggregate: AggregatePeriod) -> AnySequence<Date> {
        switch aggregate{
            case .day: return AnySequence(daysSequence())
            case .month: return AnySequence(monthsSequence())
                //TODO:
            case .week: return AnySequence(daysSequence())
        }
    }
}
