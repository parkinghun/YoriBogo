//
//  Notification+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-16.
//

import Foundation

extension Notification.Name {
    /// 레시피가 업데이트(수정)되었을 때 전송되는 알림
    static let recipeDidUpdate = Notification.Name("recipeDidUpdate")

    /// 레시피가 삭제되었을 때 전송되는 알림
    static let recipeDidDelete = Notification.Name("recipeDidDelete")

    /// 새 레시피가 생성되었을 때 전송되는 알림
    static let recipeDidCreate = Notification.Name("recipeDidCreate")
}

/// Notification의 userInfo에 담길 키 값
extension Notification {
    struct RecipeKey {
        static let recipe = "recipe"
        static let recipeId = "recipeId"
    }
}
