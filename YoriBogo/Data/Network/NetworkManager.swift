//
//  NetworkManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import Alamofire

final class NetworkManager {
    static let shared = NetworkManager()
    private init() { }
    
    private let key = Bundle.getSecrets(for: .key)
    
    private var url: String {
        "https://openapi.foodsafetykorea.go.kr/api/\(key)/COOKRCP01/json/1/1000"
    }
    
    /// 전체 레시피를 가져옵니다. Realm에 데이터가 있으면 Realm에서, 없으면 API 호출 후 Realm에 저장합니다.
    func fetchAllRecipes() async throws -> [Recipe] {
        let realmManager = RecipeRealmManager.shared

        if realmManager.hasRecipes() {
            return realmManager.fetchAllRecipes()
        }
        
        let recipes = try await fetchAllRecipesFromAPI()
        try await realmManager.saveAllRecipes(recipes)
        return recipes
    }

    /// API에서 전체 레시피를 다운로드합니다 (1000개씩 2번 호출)
    private func fetchAllRecipesFromAPI() async throws -> [Recipe] {
        var allRecipes: [Recipe] = []
        let maxPerRequest = 1000
        var currentStart = 1
        var hasMoreData = true

        while hasMoreData {
            let currentEnd = min(currentStart + maxPerRequest - 1, 1200)

            do {
                let response = try await fetchRecipes(start: currentStart, end: currentEnd)
                let recipes = response.body.row.map { $0.toEntity() }

                allRecipes.append(contentsOf: recipes)

                let totalCount = Int(response.body.totalCount) ?? 0

                if recipes.count < maxPerRequest || currentEnd >= totalCount || allRecipes.count >= totalCount {
                    hasMoreData = false
                } else {
                    currentStart = currentEnd + 1
                    // API 부하 방지를 위한 딜레이
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
                }
            } catch {
                // 일부 데이터라도 있으면 그것을 반환
                if !allRecipes.isEmpty {
                    print("부분 성공: \(allRecipes.count)개 레시피 반환")
                    break
                } else {
                    throw error
                }
            }
        }

        return allRecipes
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
