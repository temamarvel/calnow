//
//  HealthKitManager.swift
//  calnow
//
//  Created by Артем Денисов on 05.11.2025.
//


import Foundation
internal import HealthKit
internal import Combine
import HealthKitDataService

enum PredefinedDateInterval: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case last6Month
    
    var id: Self { self }
    
    var title: String {
        switch self {
            case .last7Days:   return "7 дней"
            case .last30Days:  return "30 дней"
            case .last6Month: return "6 мсяцев"
        }
    }
    
    
    private func getDateInterval(for offsetDays: Int) -> DateInterval {
        //        let startDate = Calendar.current.startOfDay(for: Date())
        let now = Date()
        
        // Дата offsetDays дней назад
        guard let offsetDate = Calendar.current.date(byAdding: .day, value: -offsetDays, to: now) else {
            // На всякий случай fallback: если что-то пошло не так — интервал из "сейчас" в "сейчас"
            return DateInterval(start: now, end: now)
        }
        
        // Начало суток того дня (00:00 локального календаря/таймзоны)
        let startOfInterval = self == .last6Month ? Calendar.current.startOfMonth(for: offsetDate)  : Calendar.current.startOfDay(for: offsetDate)
        
        return DateInterval(start: startOfInterval, end: now)
    }
    
    var daysInterval: DateInterval {
        //return getDateInterval(for: self.daysCount)
        
        switch self {
            case .last7Days:   return getDateInterval(for: 7)
            case .last30Days:  return getDateInterval(for: 30)
            case .last6Month: return getDateInterval(for: 180)
        }
    }
    
    var daysCount: Int {
        switch self {
            case .last7Days:   return 7
            case .last30Days:  return 30
            case .last6Month: return daysInterval.calendarDaysCount()
        }
    }
}
