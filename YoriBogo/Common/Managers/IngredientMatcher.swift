//
//  IngredientMatcher.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-09.
//

import Foundation

enum IngredientMatcher {
    /// 재료명이 매칭되는지 확인
    /// - Parameters:
    ///   - recipeIngredient: 레시피 재료
    ///   - userIngredient: 사용자 재료
    ///   - caseSensitive: 대소문자 구분 여부
    /// - Returns: 매칭 여부
    /// - Note: 정확히 일치하거나, 접두사로 시작하고 다음 문자가 공백인 경우 true
    static func isMatch(
        recipeIngredient: String,
        userIngredient: String,
        caseSensitive: Bool = false
    ) -> Bool {
        let recipe = caseSensitive ? recipeIngredient : recipeIngredient.lowercased()
        let user = caseSensitive ? userIngredient : userIngredient.lowercased()

        // 1. 정확히 일치
        if recipe == user {
            return true
        }

        // 2. 레시피 재료가 사용자 재료로 시작하고 다음 문자가 공백이거나 끝
        if isWordPrefixMatch(target: recipe, prefix: user) {
            return true
        }

        // 3. 사용자 재료가 레시피 재료로 시작하고 다음 문자가 공백이거나 끝
        if isWordPrefixMatch(target: user, prefix: recipe) {
            return true
        }

        return false
    }

    /// 단어 접두사 매칭 확인
    /// - Parameters:
    ///   - target: 대상 문자열
    ///   - prefix: 접두사
    /// - Returns: 접두사로 시작하고 다음 문자가 공백이거나 끝이면 true
    private static func isWordPrefixMatch(target: String, prefix: String) -> Bool {
        guard target.hasPrefix(prefix) else {
            return false
        }

        let nextIndex = target.index(target.startIndex, offsetBy: prefix.count)
        return nextIndex == target.endIndex || target[nextIndex] == " "
    }

    /// 레시피의 매칭된 재료 찾기
    /// - Parameters:
    ///   - recipeIngredients: 레시피 재료 목록
    ///   - userIngredients: 사용자 재료 목록
    /// - Returns: 매칭된 재료 목록
    static func findMatchedIngredients(
        recipeIngredients: [String],
        userIngredients: [String]
    ) -> [String] {
        return recipeIngredients.filter { recipeIngredient in
            userIngredients.contains { userIngredient in
                isMatch(recipeIngredient: recipeIngredient, userIngredient: userIngredient)
            }
        }
    }

    /// 매칭률 계산
    /// - Parameters:
    ///   - recipeIngredients: 레시피 재료 목록
    ///   - userIngredients: 사용자 재료 목록
    /// - Returns: 매칭률 (0.0 ~ 1.0)
    static func calculateMatchRate(
        recipeIngredients: [String],
        userIngredients: [String]
    ) -> Double {
        guard !recipeIngredients.isEmpty else { return 0.0 }

        let matchedCount = findMatchedIngredients(
            recipeIngredients: recipeIngredients,
            userIngredients: userIngredients
        ).count

        return Double(matchedCount) / Double(recipeIngredients.count)
    }

    /// 부족한 재료 찾기
    /// - Parameters:
    ///   - recipeIngredients: 레시피 재료 목록
    ///   - userIngredients: 사용자 재료 목록
    /// - Returns: 부족한 재료 목록
    static func findMissingIngredients(
        recipeIngredients: [String],
        userIngredients: [String]
    ) -> [String] {
        return recipeIngredients.filter { recipeIngredient in
            !userIngredients.contains { userIngredient in
                isMatch(recipeIngredient: recipeIngredient, userIngredient: userIngredient)
            }
        }
    }
}
