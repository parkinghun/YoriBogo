//
//  RecipeBootstrapService.swift
//  YoriBogo
//
//  Created by Codex on 2/18/26.
//

import Foundation

final class RecipeBootstrapService {
    static let shared = RecipeBootstrapService()

    private let maxRetryCount = 2
    private let baseRetryDelayNanoseconds: UInt64 = 1_000_000_000

    private init() { }

    /// 앱 시작 시 전체 레시피를 로드합니다.
    func preloadRecipesOnAppLaunch() {
        Task {
            do {
                _ = try await fetchAllRecipesWithRetry()
            } catch {
                print("❌ 레시피 로드 최종 실패: \(error)")
            }
        }
    }

    private func fetchAllRecipesWithRetry() async throws -> [Recipe] {
        var attempt = 0

        while true {
            do {
                return try await NetworkManager.shared.fetchAllRecipes()
            } catch {
                if error is CancellationError {
                    throw error
                }

                guard attempt < maxRetryCount else {
                    throw error
                }

                attempt += 1
                let delay = baseRetryDelayNanoseconds * UInt64(attempt)
                print("⚠️ 레시피 로드 실패, \(attempt)/\(maxRetryCount) 재시도: \(error)")
                try await Task.sleep(nanoseconds: delay)
            }
        }
    }
}
