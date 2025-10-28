//
//  UIImage+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/5/25.
//

import UIKit

extension UIImage {
    /// 재료 이미지를 로드합니다. asset에 없는 경우 카테고리별 fallback 이미지를 반환합니다.
    /// - Parameters:
    ///   - imageKey: 재료 이미지 키
    ///   - categoryId: 재료 카테고리 ID
    /// - Returns: 재료 이미지 또는 fallback 이미지
    static func ingredientImage(imageKey: String, categoryId: Int) -> UIImage? {
        // 먼저 imageKey로 이미지를 찾음
        if let image = UIImage(named: imageKey) {
            return image
        }

        // 없으면 카테고리별 fallback 이미지 반환
        let fallbackImageName = fallbackImageName(for: categoryId)
        return UIImage(named: fallbackImageName)
    }

    /// 카테고리 ID에 따른 fallback 이미지 이름을 반환합니다.
    /// - Parameter categoryId: 재료 카테고리 ID
    /// - Returns: fallback 이미지 이름
    private static func fallbackImageName(for categoryId: Int) -> String {
        switch categoryId {
        case 1: // 과일·채소
            return "tomato"
        case 2: // 빵·곡물·조식류
            return "bread"
        case 3: // 고기·단백질
            return "meat"
        case 4: // 유제품·계란
            return "cheese"
        case 5: // 양념·조미료
            return "salt"
        case 6: // 해산물
            return "fish"
        default:
            return "tomato" // 기본값
        }
    }
}
