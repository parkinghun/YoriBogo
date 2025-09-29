//
//  UIFont+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

enum Pretendard: String {
    case black = "Pretendard-Black"
    case bold = "Pretendard-Bold"
    case extraBold = "Pretendard-ExtraBold"
    case extraLight = "Pretendard-ExtraLight"
    case light = "Pretendard-Light"
    case medium = "Pretendard-Medium"
    case regular = "Pretendard-Regular"
    case semiBold = "Pretendard-SemiBold"
    case thin = "Pretendard-Thin"
    
    func of(size: CGFloat) -> UIFont {
        return UIFont(name: self.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}

enum AppFont {
    /// 가장 중요한 텍스트 (20px Bold)
    static let pageTitle = Pretendard.bold.of(size: 20)
    
    /// 중요한 제목 (18px SemiBold)
    static let sectionTitle = Pretendard.semiBold.of(size: 18)
    
    /// 카드/아이템 이름 (16px Medium)
    static let itemTitle = Pretendard.medium.of(size: 16)
    
    /// 기본 본문 (16px Regular)
    static let body = Pretendard.regular.of(size: 16)
    
    /// 버튼/폼 라벨 (14px Medium)
    static let button = Pretendard.medium.of(size: 14)
    
    /// 작은 정보 (12px Regular)
    static let caption = Pretendard.regular.of(size: 12)
    
    /// 특수 숫자 (24px Bold Mono)
    static let timer = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
}
