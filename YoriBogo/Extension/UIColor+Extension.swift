//
//  UIColor+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

import UIKit

extension UIColor {
    // MARK: - Primary (Orange)
    static let brandOrange400 = UIColor(hex: "#FB923C")
    static let brandOrange500 = UIColor(hex: "#F97316") // 메인 CTA
    static let brandOrange600 = UIColor(hex: "#EA580C") // 메인 브랜드 컬러 ⭐
    static let brandOrange200 = UIColor(hex: "#FED7AA") // Hover
    static let brandOrange100 = UIColor(hex: "#FFEDD5")
    static let brandOrange50  = UIColor(hex: "#FFF7ED")
    
    // MARK: - Secondary (Yellow)
    static let brandYellow100 = UIColor(hex: "#FEF3C7")
    static let brandYellow50  = UIColor(hex: "#FEF9E7")
    
    // MARK: - Status: Green
    static let statusGreen500 = UIColor(hex: "#10B981") // 소진
    static let statusGreen600 = UIColor(hex: "#059669")
    static let statusGreen700 = UIColor(hex: "#047857")
    static let statusGreen300 = UIColor(hex: "#6EE7B7")
    static let statusGreen200 = UIColor(hex: "#A7F3D0")
    static let statusGreen100 = UIColor(hex: "#D1FAE5")
    static let statusGreen50  = UIColor(hex: "#ECFDF5")
    
    // MARK: - Status: Red
    static let statusRed500 = UIColor(hex: "#EF4444") // 폐기
    static let statusRed600 = UIColor(hex: "#DC2626")
    static let statusRed300 = UIColor(hex: "#FCA5A5")
    static let statusRed200 = UIColor(hex: "#FECACA")
    static let statusRed100 = UIColor(hex: "#FEE2E2")
    static let statusRed50  = UIColor(hex: "#FEF2F2")
    
    // MARK: - Gray Scale
    static let gray900 = UIColor(hex: "#111827")
    static let gray800 = UIColor(hex: "#1F2937")
    static let gray700 = UIColor(hex: "#374151")
    static let gray600 = UIColor(hex: "#4B5563")
    static let gray500 = UIColor(hex: "#6B7280")
    static let gray400 = UIColor(hex: "#9CA3AF")
    static let gray300 = UIColor(hex: "#D1D5DB")
    static let gray200 = UIColor(hex: "#E5E7EB")
    static let gray100 = UIColor(hex: "#F3F4F6")
    static let gray50  = UIColor(hex: "#F9FAFB")
    
    // MARK: - Special
    static let statusOrangeWarning = UIColor(hex: "#F59E0B") // D-3~5
    static let purple500 = UIColor(hex: "#8B5CF6") // 요리 마스터
    static let purple100 = UIColor(hex: "#DDD6FE")
    static let blue500   = UIColor(hex: "#3B82F6") // 요리 전문가
    static let blue100   = UIColor(hex: "#DBEAFE")
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

