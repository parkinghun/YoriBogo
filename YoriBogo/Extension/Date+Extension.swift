//
//  Date+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import Foundation

// 냉장고 리스트 화면에서 D-day 표시
extension Date {
    func daysUntil() -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: self)
        return components.day
    }
    
    func formattedExpirationDate() -> String {
        return DateFormatter.expirationDate.string(from: self)
    }
}
