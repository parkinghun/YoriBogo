//
//  UIColor+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

import UIKit

extension UIColor {
    // MARK: - Custom Colors
    /// 밝은 베이지톤 배경
    static let beige100 = UIColor(hex: "#FAF5EB")
    
    // MARK: - Primary (Orange)
    /// 그라디언트 시작색
    static let brandOrange400 = UIColor(hex: "#FB923C")
    /// 메인 브랜드 컬러 ⭐
    static let brandOrange500 = UIColor(hex: "#F97316") // 메인 CTA
    /// Hover
    static let brandOrange600 = UIColor(hex: "#EA580C")
    /// 미리보기 힌트
    static let brandOrange200 = UIColor(hex: "#FED7AA") // Hover
    /// 라이트 배경
    static let brandOrange100 = UIColor(hex: "#FFEDD5")
    /// 매우 연한 배경
    static let brandOrange50  = UIColor(hex: "#FFF7ED")
    
    // MARK: - Secondary (Yellow)
    /// 그라디언트 배경용
    static let brandYellow100 = UIColor(hex: "#FEF3C7")
    /// 그라디언트 배경용
    static let brandYellow50  = UIColor(hex: "#FEF9E7")
    
    // MARK: - Status: Green
    /// 소진 버튼, 완료된 타이머
    static let statusGreen500 = UIColor(hex: "#10B981")
    /// Hover 상태
    static let statusGreen600 = UIColor(hex: "#059669")
    /// 텍스트
    static let statusGreen700 = UIColor(hex: "#047857")
    /// 매치된 재료 아이콘
    static let statusGreen300 = UIColor(hex: "#6EE7B7")
    /// 완료 상태 링
    static let statusGreen200 = UIColor(hex: "#A7F3D0")
    /// 라이트 배경
    static let statusGreen100 = UIColor(hex: "#D1FAE5")
    /// 매우 연한 배경
    static let statusGreen50  = UIColor(hex: "#ECFDF5")
    
    // MARK: - Status: Red
    /// 폐기 버튼, 경고
    static let statusRed500 = UIColor(hex: "#EF4444")
    /// Hover 상태
    static let statusRed600 = UIColor(hex: "#DC2626")
    /// 1분 이하 타이머 경고
    static let statusRed300 = UIColor(hex: "#FCA5A5")
    /// 경고 배경
    static let statusRed200 = UIColor(hex: "#FECACA")
    /// 라이트 배경
    static let statusRed100 = UIColor(hex: "#FEE2E2")
    /// 매우 연한 배경
    static let statusRed50  = UIColor(hex: "#FEF2F2")
    
    // MARK: - Gray Scale
    /// 메인 제목, 중요한 텍스트에 사용되는 색상
    static let gray800 = UIColor(hex: "#1F2937")
    /// 일반 텍스트, 아이콘에 사용되는 색상
    static let gray700 = UIColor(hex: "#374151")
    /// 보조 텍스트에 사용되는 색상
    static let gray600 = UIColor(hex: "#4B5563")
    /// 비활성, 플레이스홀더에 사용되는 색상
    static let gray500 = UIColor(hex: "#6B7280")
    /// 라이트 아이콘, 구분선에 사용되는 색상
    static let gray400 = UIColor(hex: "#9CA3AF")
    /// 비활성 인디케이터, 경계선에 사용되는 색상
    static let gray300 = UIColor(hex: "#D1D5DB")
    /// 입력 필드 경계선에 사용되는 색상
    static let gray200 = UIColor(hex: "#E5E7EB")
    /// 카드 배경, 비활성 버튼에 사용되는 색상
    static let gray100 = UIColor(hex: "#F3F4F6")
    /// 페이지 배경에 사용되는 색상
    static let gray50  = UIColor(hex: "#F9FAFB")
    
    // MARK: - Special
    /// D-3~5 경고 상태에 사용되는 주황색
    static let statusOrangeWarning = UIColor(hex: "#F59E0B")
    /// 요리 마스터에 사용되는 보라색
    static let purple500 = UIColor(hex: "#8B5CF6")
    /// 연한 보라색
    static let purple100 = UIColor(hex: "#DDD6FE")
    /// 요리 전문가에 사용되는 파란색
    static let blue500   = UIColor(hex: "#3B82F6")
    /// 연한 파란색
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

