//
//  NetworkManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import Alamofire

private enum RecipeFetchError: LocalizedError {
    case partialDownload(downloaded: Int, expected: Int, underlying: Error)
    case incompleteDownload(downloaded: Int, expected: Int)

    var errorDescription: String? {
        switch self {
        case .partialDownload(let downloaded, let expected, let underlying):
            return "레시피 부분 다운로드 실패 (\(downloaded)/\(expected)): \(underlying.localizedDescription)"
        case .incompleteDownload(let downloaded, let expected):
            return "레시피 데이터가 불완전합니다 (\(downloaded)/\(expected))"
        }
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() { }
    
    private let key = Bundle.getSecrets(for: .key)
    private let metadataStore = UserDefaults.standard
    private let recipeCacheExpectedCountKey = "recipeCacheExpectedCount"
    private let maxRecipeFetchLimit = 1200
    private let maxPerRequest = 1000
    
    private var url: String {
        "https://openapi.foodsafetykorea.go.kr/api/\(key)/COOKRCP01/json/1/1000"
    }
    
    /// 전체 레시피를 가져옵니다. Realm에 데이터가 있으면 Realm에서, 없으면 API 호출 후 Realm에 저장합니다.
    func fetchAllRecipes() async throws -> [Recipe] {
        let realmManager = RecipeRealmManager.shared
        let cachedCount = realmManager.getRecipeCount()

        if cachedCount > 0 && isValidRecipeCache(cachedCount: cachedCount) {
            return realmManager.fetchAllRecipes()
        }

        if cachedCount > 0 {
            print("⚠️ 레시피 캐시 무결성 검증 실패(\(cachedCount)개), API 재동기화를 시도합니다.")
        }

        let fetchResult = try await fetchAllRecipesFromAPI()
        try await realmManager.saveAllRecipes(fetchResult.recipes)
        saveExpectedRecipeCount(fetchResult.expectedCount)
        return fetchResult.recipes
    }

    /// API에서 전체 레시피를 다운로드합니다 (1000개씩 2번 호출)
    private func fetchAllRecipesFromAPI() async throws -> (recipes: [Recipe], expectedCount: Int) {
        var allRecipes: [Recipe] = []
        var currentStart = 1
        var hasMoreData = true
        var expectedCount = 0

        while hasMoreData {
            let currentEnd = min(currentStart + maxPerRequest - 1, maxRecipeFetchLimit)

            do {
                let response = try await fetchRecipes(start: currentStart, end: currentEnd)
                let recipes = response.body.row.map { $0.toEntity() }

                allRecipes.append(contentsOf: recipes)

                let totalCount = Int(response.body.totalCount) ?? 0
                if totalCount > 0 {
                    expectedCount = min(totalCount, maxRecipeFetchLimit)
                } else {
                    expectedCount = max(expectedCount, allRecipes.count)
                }

                if recipes.count < maxPerRequest || currentEnd >= totalCount || allRecipes.count >= totalCount {
                    hasMoreData = false
                } else {
                    currentStart = currentEnd + 1
                    // API 부하 방지를 위한 딜레이
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
                }
            } catch {
                // 부분 성공은 실패로 처리하여 다음 실행에서 재시도되도록 함
                if !allRecipes.isEmpty {
                    let targetCount = max(expectedCount, allRecipes.count)
                    throw RecipeFetchError.partialDownload(
                        downloaded: allRecipes.count,
                        expected: targetCount,
                        underlying: error
                    )
                } else {
                    throw error
                }
            }
        }

        if expectedCount > 0 && allRecipes.count < expectedCount {
            throw RecipeFetchError.incompleteDownload(downloaded: allRecipes.count, expected: expectedCount)
        }

        return (recipes: allRecipes, expectedCount: max(expectedCount, allRecipes.count))
    }

    private func isValidRecipeCache(cachedCount: Int) -> Bool {
        let expectedCount = metadataStore.integer(forKey: recipeCacheExpectedCountKey)

        if expectedCount > 0 {
            return cachedCount >= expectedCount
        }

        // 기존 버전에서 메타데이터가 없던 경우, fetch limit 기준으로 최소 무결성을 확인
        return cachedCount >= maxRecipeFetchLimit
    }

    private func saveExpectedRecipeCount(_ expectedCount: Int) {
        guard expectedCount > 0 else { return }
        metadataStore.set(expectedCount, forKey: recipeCacheExpectedCountKey)
    }
    
    private func fetchRecipes(start: Int, end: Int) async throws -> RecipeResponseDTO {
        let url = "https://openapi.foodsafetykorea.go.kr/api/\(key)/COOKRCP01/json/\(start)/\(end)"
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: RecipeResponseDTO.self) { response in
                    switch response.result {
                    case .success(let dto):
                        let resultCode = dto.body.result.code
                        let resultMessage = dto.body.result.message
                        
                        switch resultCode {
                        case "INFO-000":
                            continuation.resume(returning: dto)
                        case "INFO-200":
                            print("해당 범위에 데이터가 없습니다: \(resultMessage)")
                            continuation.resume(returning: dto)
                        case "INFO-300":
                            let error = NSError(domain: "API", code: 300, userInfo: [NSLocalizedDescriptionKey: "API 호출 한도 초과: \(resultMessage)"])
                            continuation.resume(throwing: error)
                        case "INFO-400":
                            let error = NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: "API 권한 오류: \(resultMessage)"])
                            continuation.resume(throwing: error)
                        default:
                            let error = NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: "\(resultCode): \(resultMessage)"])
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
