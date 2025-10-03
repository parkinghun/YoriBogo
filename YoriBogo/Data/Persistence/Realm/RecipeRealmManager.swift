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
}
