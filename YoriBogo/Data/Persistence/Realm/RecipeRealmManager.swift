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
    
    private let realm: Realm
    
    private init() {
        do {
            let config = Realm.Configuration(
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                        // 마이그레이션 로직 추가 가능
                    }
                }
            )
            Realm.Configuration.defaultConfiguration = config
            self.realm = try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
    }
    
    // MARK: - 전체 레시피 저장 (API에서 받은 데이터)
    @MainActor
    func saveAllRecipes(_ recipes: [Recipe]) async throws {
        let objects = recipes.map { RecipeObject(from: $0) }
        do {
            try await realm.asyncWrite {
                realm.add(objects, update: Realm.UpdatePolicy.modified)
            }
            print("✅ \(recipes.count)개 레시피 Realm 저장 완료")
        } catch {
            print("전체 레시피 저장 실패")
        }
        
    }
    
    // MARK: - 전체 레시피 가져오기
    func fetchAllRecipes() -> [Recipe] {
        let objects = realm.objects(RecipeObject.self)
        return objects.map { $0.toEntity() }
    }
    
    // MARK: - 전체 레시피 개수 확인
    func getRecipeCount() -> Int {
        return realm.objects(RecipeObject.self).count
    }
    
    // MARK: - 레시피 존재 여부 확인
    func hasRecipes() -> Bool {
        return !realm.objects(RecipeObject.self).isEmpty
    }
    
    // MARK: - 특정 레시피 가져오기 (ID로)
    func fetchRecipe(by id: String) -> Recipe? {
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: id) else {
            return nil
        }
        return object.toEntity()
    }
    
    // MARK: - 특정 레시피 가져오기 (baseId로)
    func fetchRecipes(byBaseId baseId: String) -> [Recipe] {
        let objects = realm.objects(RecipeObject.self).filter("baseId == %@", baseId)
        return objects.map { $0.toEntity() }
    }
    
    // MARK: - 레시피 업데이트
    func updateRecipe(_ recipe: Recipe) throws {
        let object = RecipeObject(from: recipe)
        
        try realm.write {
            realm.add(object, update: .modified)
        }
    }
    
    // MARK: - 레시피 삭제
    func deleteRecipe(by id: String) throws {
        guard let object = realm.object(ofType: RecipeObject.self, forPrimaryKey: id) else {
            return
        }
        
        try realm.write {
            realm.delete(object)
        }
    }
    
    // MARK: - 전체 레시피 삭제 (테스트/리셋용)
    func deleteAllRecipes() throws {
        let objects = realm.objects(RecipeObject.self)
        
        try realm.write {
            realm.delete(objects)
        }
        
        print("🗑️ 모든 레시피 삭제 완료")
    }
    
    // MARK: - 카테고리별 레시피 가져오기
    func fetchRecipes(byCategory category: String) -> [Recipe] {
        let objects = realm.objects(RecipeObject.self).filter("category == %@", category)
        return objects.map { $0.toEntity() }
    }
    
    // MARK: - 검색 (제목, 태그, 재료)
    func searchRecipes(keyword: String) -> [Recipe] {
        let objects = realm.objects(RecipeObject.self)
            .filter("searchText CONTAINS[c] %@", keyword)
        return objects.map { $0.toEntity() }
    }
    
    // MARK: - 북마크 토글
    func toggleBookmark(recipeId: String) throws {
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
        let objects = realm.objects(RecipeObject.self).filter("isBookmarked == true")
        return objects.map { $0.toEntity() }
    }
}
