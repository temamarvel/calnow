//
//  HealthKitManager.swift
//  calnow
//
//  Created by Артем Денисов on 05.11.2025.
//


import Foundation
internal import HealthKit
internal import Combine

enum PredefinedDateInterval: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case last180Days
    
    var id: Self { self }
    
        var title: String {
            switch self {
                case .last7Days:   return "7 дней"
                case .last30Days:  return "30 дней"
                case .last180Days: return "180 дней"
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
        let startOfDay = Calendar.current.startOfDay(for: offsetDate)
        
        return DateInterval(start: startOfDay, end: now)
    }
    
    var daysInterval: DateInterval {
        return getDateInterval(for: self.daysCount)
    }
    
    var daysCount: Int {
        switch self {
            case .last7Days:   return 7
            case .last30Days:  return 30
            case .last180Days: return 180
        }
    }
}
