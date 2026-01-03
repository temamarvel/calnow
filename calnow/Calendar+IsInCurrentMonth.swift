//
//  Calendar+IsInCurrentMonth.swift
//  calnow
//
//  Created by Артем Денисов on 04.01.2026.
//

import Foundation

extension Calendar {
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let now = Date()
        let dateComponents = self.dateComponents([.year, .month], from: date)
        let nowComponents  = self.dateComponents([.year, .month], from: now)
        
        return dateComponents.year == nowComponents.year &&
        dateComponents.month == nowComponents.month
    }
}
