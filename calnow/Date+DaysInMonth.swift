//
//  Date+DaysInMonth.swift
//  calnow
//
//  Created by Артем Денисов on 21.12.2025.
//

import Foundation

extension Date {
    func daysInMonth(calendar: Calendar = .current) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: self) else {
            return 0
        }
        return range.count
    }
    
    func daysFromMonthStart(calendar: Calendar = .current) -> Int {
        calendar.component(.day, from: self)
    }
}
