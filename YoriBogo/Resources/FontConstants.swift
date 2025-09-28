//
//  FontConstants.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

struct FontConstants {
    
    // MARK: XS (12px) - 아주 작은 정보
    static let bodyXS = Pretendard.regular.of(size: 12)
    static let bodyXSMedium = Pretendard.medium.of(size: 12)
    
    // MARK: SM (14px) - 작은 정보/버튼
    static let bodySM = Pretendard.regular.of(size: 14)
    static let bodySMMedium = Pretendard.medium.of(size: 14)
    static let bodySMSemiBold = Pretendard.semiBold.of(size: 14)
    
    // MARK: Base (16px) - 본문
    static let bodyBase = Pretendard.regular.of(size: 16)
    static let bodyBaseMedium = Pretendard.medium.of(size: 16)
    
    // MARK: LG (18px) - 중간 제목
    static let titleLG = Pretendard.regular.of(size: 18)
    static let titleLGSemiBold = Pretendard.semiBold.of(size: 18)
    
    // MARK: XL (20px) - 주요 제목
    static let titleXL = Pretendard.regular.of(size: 20)
    static let titleXLBold = Pretendard.bold.of(size: 20)
    
    // MARK: 2XL (24px) - 강조 텍스트, 통계
    static let title2XL = Pretendard.regular.of(size: 24)
    static let title2XLBold = Pretendard.bold.of(size: 24)
    
    // MARK: 3XL (30px) - 큰 아이콘/빈 상태
    static let title3XL = Pretendard.regular.of(size: 30)
    static let title3XLBold = Pretendard.bold.of(size: 30)
    
    // MARK: 4XL (36px) - 초대형 아이콘
    static let title4XL = Pretendard.regular.of(size: 36)
    static let title4XLBold = Pretendard.bold.of(size: 36)
    
    // MARK: 특수 폰트
    static let timerFont = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
    static let timerFontLarge = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .bold)
}
