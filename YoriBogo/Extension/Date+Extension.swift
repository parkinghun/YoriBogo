//
//  Date+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import Foundation
import UIKit

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

    /// D-Day 정보를 반환 (일수, 텍스트, 색상)
    struct DDayInfo {
        let daysLeft: Int
        let text: String
        let backgroundColor: UIColor
        let textColor: UIColor
        let isExpired: Bool
    }

    /// D-Day 정보 계산
    func getDDayInfo() -> DDayInfo? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiration = calendar.startOfDay(for: self)

        guard let daysLeft = calendar.dateComponents([.day], from: today, to: expiration).day else {
            return nil
        }

        let text: String
        let backgroundColor: UIColor
        let textColor: UIColor = .white
        let isExpired: Bool

        switch daysLeft {
        case ..<0:
            text = "만료"
            backgroundColor = .gray400
            isExpired = true
        case 0:
            text = "D-Day"
            backgroundColor = .systemRed
            isExpired = false
        case 1...3:
            text = "D-\(daysLeft)"
            backgroundColor = .systemRed
            isExpired = false
        case 4...7:
            text = "D-\(daysLeft)"
            backgroundColor = .systemOrange
            isExpired = false
        default:
            text = "D-\(daysLeft)"
            backgroundColor = .gray200
            isExpired = false
        }

        return DDayInfo(
            daysLeft: daysLeft,
            text: text,
            backgroundColor: backgroundColor,
            textColor: textColor,
            isExpired: isExpired
        )
    }

    /// 스마트 소비기한 표시 (같은 연도면 월/일만, 다른 연도면 년/월/일)
    func formattedExpirationDateSmart() -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let expirationYear = calendar.component(.year, from: self)

        if currentYear == expirationYear {
            return DateFormatter.expirationDetailSameYear.string(from: self)
        } else {
            return DateFormatter.expirationDetailDifferentYear.string(from: self)
        }
    }
}
