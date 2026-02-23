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
        }.value
    }

    func fetchAllRecipes() -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self)
        return objects.map { $0.toEntity() }
    }

    func getRecipeCount() -> Int {
        let realm = try! getRealm()
        return realm.objects(RecipeObject.self).count
    }

    func hasRecipes() -> Bool {
        let realm = try! getRealm()
        return !realm.objects(RecipeObject.self).isEmpty
    }
    
    func fetchRecipe(by id: String) -> Recipe? {
        let realm = try! getRealm()
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: id) else {
            return nil
        }
        return object.toEntity()
    }

    func fetchRecipes(byBaseId baseId: String) -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("baseId == %@", baseId)
        return objects.map { $0.toEntity() }
    }

    func updateRecipe(_ recipe: Recipe) throws {
        let realm = try getRealm()
        let object = RecipeObject(from: recipe)

        try realm.write {
            realm.add(object, update: .modified)
        }
    }

    func deleteRecipe(by id: String) throws {
        let realm = try getRealm()
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: id) else {
            return
        }

        let recipe = object.toEntity()
        ImagePathHelper.shared.deleteAllImagesForRecipe(recipe)

        try realm.write {
            realm.delete(object)
        }
    }

    func deleteAllRecipes() throws {
        let realm = try getRealm()
        let objects = realm.objects(RecipeObject.self)

        try realm.write {
            realm.delete(objects)
        }
    }

    func fetchRecipes(byCategory category: String) -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("category == %@", category)
        return objects.map { $0.toEntity() }
    }

    func searchRecipes(keyword: String) -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self)
            .filter("searchText CONTAINS[c] %@", keyword)
        return objects.map { $0.toEntity() }
    }

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

    func fetchBookmarkedRecipes() -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("isBookmarked == true")
        return objects.map { $0.toEntity() }
    }

    func fetchUserRecipes() -> [Recipe] {
        let realm = try! getRealm()
        let objects = realm.objects(RecipeObject.self).filter("kind == %@ OR kind == %@", RecipeKind.userOriginal.rawValue, RecipeKind.userModified.rawValue)
        let recipes = objects.map { $0.toEntity() }

        return recipes.sorted { recipe1, recipe2 in
            let date1 = recipe1.updatedAt ?? recipe1.createdAt
            let date2 = recipe2.updatedAt ?? recipe2.createdAt
            return date1 > date2
        }
    }


    func fetchRecommendedRecipes(userIngredients: [String], maxCount: Int = 5) -> [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] {
        let realm = try! getRealm()
        let allRecipes = realm.objects(RecipeObject.self).map { $0.toEntity() }

        if userIngredients.isEmpty {
            let randomRecipes = Array(allRecipes.shuffled().prefix(maxCount))
            return randomRecipes.map { ($0, 0.0, []) }
        }

        let recipesWithMatchRate: [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] = allRecipes.map { recipe in
            let recipeIngredientNames = recipe.ingredients.map { $0.name.lowercased() }
            let userIngredientsLower = userIngredients.map { $0.lowercased() }

            let matchedIngredients = IngredientMatcher.findMatchedIngredients(
                recipeIngredients: recipeIngredientNames,
                userIngredients: userIngredientsLower
            )

            let matchRate = IngredientMatcher.calculateMatchRate(
                recipeIngredients: recipeIngredientNames,
                userIngredients: userIngredientsLower
            )

            return (recipe, matchRate, matchedIngredients)
        }

        let sortedRecipes = recipesWithMatchRate.sorted { $0.matchRate > $1.matchRate }

        let matchedRecipes = sortedRecipes.filter { $0.matchRate > 0 }

        if matchedRecipes.count >= maxCount {
            return Array(matchedRecipes.prefix(maxCount))
        } else {
            let nonMatchedRecipes = sortedRecipes.filter { $0.matchRate == 0 }.shuffled()
            let needed = maxCount - matchedRecipes.count
            let randomRecipes = Array(nonMatchedRecipes.prefix(needed))
            return matchedRecipes + randomRecipes
        }
    }
}
