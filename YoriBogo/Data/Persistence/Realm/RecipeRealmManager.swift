//
//  RecipeRealmManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import RealmSwift

final class RecipeRealmManager {
    static let shared = RecipeRealmManager()

    private init() {}

    // Realm 인스턴스를 항상 새로 생성하여 스레드 안전성 보장
    private func getRealm() throws -> Realm {
        return try Realm()
    }

    // MARK: - 전체 레시피 저장 (API에서 받은 데이터)
    func saveAllRecipes(_ recipes: [Recipe]) async throws {
        // 백그라운드 스레드에서 Realm 작업 수행
        try await Task.detached {
            let realm = try Realm()
            let objects = recipes.map { RecipeObject(from: $0) }

            try realm.write {
                realm.add(objects, update: .modified)
            }

            print("✅ \(recipes.count)개 레시피 Realm 저장 완료")
        }.value
    }

    // MARK: - 전체 레시피 가져오기
    func fetchAllRecipes() -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self)
        return objects.map { $0.toEntity() }
    }

    // MARK: - 전체 레시피 개수 확인
    func getRecipeCount() -> Int {
        let realm = try! getRealm()
        return realm.objects(RecipeObject.self).count
    }

    // MARK: - 레시피 존재 여부 확인
    func hasRecipes() -> Bool {
        let realm = try! getRealm()
        return !realm.objects(RecipeObject.self).isEmpty
    }
    
    // MARK: - 특정 레시피 가져오기 (ID로)
    func fetchRecipe(by id: String) -> Recipe? {
        let realm = try! getRealm()
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: id) else {
            return nil
        }
        return object.toEntity()
    }

    // MARK: - 특정 레시피 가져오기 (baseId로)
    func fetchRecipes(byBaseId baseId: String) -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("baseId == %@", baseId)
        return objects.map { $0.toEntity() }
    }

    // MARK: - 레시피 업데이트
    func updateRecipe(_ recipe: Recipe) throws {
        let realm = try getRealm()
        let object = RecipeObject(from: recipe)

        try realm.write {
            realm.add(object, update: .modified)
        }
    }

    // MARK: - 레시피 삭제
    func deleteRecipe(by id: String) throws {
        let realm = try getRealm()
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: id) else {
            return
        }

        try realm.write {
            realm.delete(object)
        }
    }

    // MARK: - 전체 레시피 삭제 (테스트/리셋용)
    func deleteAllRecipes() throws {
        let realm = try getRealm()
        let objects = realm.objects(RecipeObject.self)

        try realm.write {
            realm.delete(objects)
        }

        print("🗑️ 모든 레시피 삭제 완료")
    }

    // MARK: - 카테고리별 레시피 가져오기
    func fetchRecipes(byCategory category: String) -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("category == %@", category)
        return objects.map { $0.toEntity() }
    }

    // MARK: - 검색 (제목, 태그, 재료)
    func searchRecipes(keyword: String) -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self)
            .filter("searchText CONTAINS[c] %@", keyword)
        return objects.map { $0.toEntity() }
    }

    // MARK: - 북마크 토글
    func toggleBookmark(recipeId: String) throws {
        let realm = try getRealm()
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: recipeId) else {
            return
        }

        try realm.write {
            object.isBookmarked.toggle()
            object.updatedAt = Date()
        }
    }

    // MARK: - 북마크된 레시피만 가져오기
    func fetchBookmarkedRecipes() -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("isBookmarked == true")
        return objects.map { $0.toEntity() }
    }

    // MARK: - 보유 재료 기반 추천 레시피
    func fetchRecommendedRecipes(userIngredients: [String], maxCount: Int = 5) -> [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] {
        let realm = try! getRealm()
        let allRecipes = realm.objects(RecipeObject.self).map { $0.toEntity() }

        // 보유 재료가 없으면 랜덤 레시피 반환
        if userIngredients.isEmpty {
            let randomRecipes = Array(allRecipes.shuffled().prefix(maxCount))
            return randomRecipes.map { ($0, 0.0, []) }
        }

        // 각 레시피의 매칭률 계산
        let recipesWithMatchRate: [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] = allRecipes.map { recipe in
            let recipeIngredientNames = recipe.ingredients.map { $0.name.lowercased() }
            let userIngredientsLower = userIngredients.map { $0.lowercased() }

            // 매칭되는 재료 찾기
            let matchedIngredients = recipeIngredientNames.filter { recipeIngredient in
                userIngredientsLower.contains { userIngredient in
                    recipeIngredient.contains(userIngredient) || userIngredient.contains(recipeIngredient)
                }
            }

            // 매칭률 계산 (매칭된 재료 수 / 전체 레시피 재료 수)
            let matchRate = recipeIngredientNames.isEmpty ? 0.0 : Double(matchedIngredients.count) / Double(recipeIngredientNames.count)

            return (recipe, matchRate, matchedIngredients)
        }

        // 매칭률로 정렬 (높은 순)
        let sortedRecipes = recipesWithMatchRate.sorted { $0.matchRate > $1.matchRate }

        // 매칭된 레시피와 랜덤 레시피 조합
        let matchedRecipes = sortedRecipes.filter { $0.matchRate > 0 }

        if matchedRecipes.count >= maxCount {
            // 매칭된 레시피가 충분하면 상위 N개만
            return Array(matchedRecipes.prefix(maxCount))
        } else {
            // 부족하면 랜덤 레시피로 채우기
            let nonMatchedRecipes = sortedRecipes.filter { $0.matchRate == 0 }.shuffled()
            let needed = maxCount - matchedRecipes.count
            let randomRecipes = Array(nonMatchedRecipes.prefix(needed))
            return matchedRecipes + randomRecipes
        }
    }
}
