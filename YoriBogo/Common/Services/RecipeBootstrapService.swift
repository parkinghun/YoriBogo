//
//  RecipeBootstrapService.swift
//  YoriBogo
//
//  Created by 박성훈 on 2/18/26.
//

import Foundation

final class RecipeBootstrapService {
    static let shared = RecipeBootstrapService()

    private let maxRetryCount = 2
    private let baseRetryDelayNanoseconds: UInt64 = 1_000_000_000
    private let lock = NSLock()
    private var bootstrapTask: Task<[Recipe], Error>?

    private init() { }

    /// 앱 시작 시 전체 레시피를 로드합니다.
    func preloadRecipesOnAppLaunch() {
        Task {
            do {
                _ = try await bootstrapRecipesIfNeeded()
            } catch {
                if error is CancellationError {
                    return
                }
                print("레시피 로드 최종 실패: \(error)")
            }
        }
    }

    private func bootstrapRecipesIfNeeded() async throws -> [Recipe] {
        let task = getOrCreateBootstrapTask()
        defer { clearBootstrapTask() }
        return try await task.value
    }

    private func getOrCreateBootstrapTask() -> Task<[Recipe], Error> {
        lock.lock()
        defer { lock.unlock() }

        if let task = bootstrapTask {
            return task
        }

        let task = Task<[Recipe], Error> {
            do {
                let recipes = try await fetchAllRecipesWithRetry()
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .recipeBootstrapDidSucceed,
                        object: nil,
                        userInfo: [Notification.RecipeBootstrapKey.recipeCount: recipes.count]
                    )
                }
                return recipes
            } catch {
                if error is CancellationError {
                    throw error
                }

                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .recipeBootstrapDidFail,
                        object: nil,
                        userInfo: [Notification.RecipeBootstrapKey.error: error]
                    )
                }
                throw error
            }
        }

        bootstrapTask = task
        return task
    }

    private func clearBootstrapTask() {
        lock.lock()
        defer { lock.unlock() }
        bootstrapTask = nil
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
                print("레시피 로드 실패, \(attempt)/\(maxRetryCount) 재시도: \(error)")
                try await Task.sleep(nanoseconds: delay)
            }
        }
    }
}
