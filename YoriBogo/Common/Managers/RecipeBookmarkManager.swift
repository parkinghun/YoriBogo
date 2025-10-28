//
//  RecipeBookmarkManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-09.
//

import Foundation

enum BookmarkError: LocalizedError {
    case recipeNotFound

    var errorDescription: String? {
        switch self {
        case .recipeNotFound:
            return "레시피를 찾을 수 없습니다"
        }
    }
}

final class RecipeBookmarkManager {
    static let shared = RecipeBookmarkManager()
    private let recipeManager = RecipeRealmManager.shared

    private init() {}

    /// 북마크를 토글하고 업데이트된 레시피를 반환
    /// - Parameter recipeId: 레시피 ID
    /// - Returns: 업데이트된 Recipe 객체
    /// - Throws: BookmarkError.recipeNotFound - 레시피를 찾을 수 없을 때
    func toggleBookmark(recipeId: String) throws -> Recipe {
        try recipeManager.toggleBookmark(recipeId: recipeId)

        guard let updatedRecipe = recipeManager.fetchRecipe(by: recipeId) else {
            throw BookmarkError.recipeNotFound
        }

        return updatedRecipe
    }

    /// 레시피의 북마크 상태를 확인
    /// - Parameter recipeId: 레시피 ID
    /// - Returns: 북마크 여부
    func isBookmarked(recipeId: String) -> Bool {
        guard let recipe = recipeManager.fetchRecipe(by: recipeId) else {
            return false
        }
        return recipe.isBookmarked
    }
}
