//
//  FridgeIngredientDataSource.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation
import RealmSwift

protocol FridgeIngredientDataSourceType {
    func save(_ ingredient: FridgeIngredientDetail) throws
    func fetchAll(sortBy: SortOption) -> [FridgeIngredientDetail]
    func fetchByCategories(_ categoryIds: [Int], sortBy: SortOption) -> [FridgeIngredientDetail]
    func delete(_ id: String) throws
}

enum SortOption {
    case basic      // 기본순 (이름순)
    case expiryDate // 소비기한 임박순
}

final class FridgeIngredientDataSource: FridgeIngredientDataSourceType {
    private let realm = try! Realm()

    func save(_ ingredient: FridgeIngredientDetail) throws {
        let object = ingredient.toRealmObject()
        do {
            try realm.write {
                realm.add(object, update: .modified)
            }
        } catch {
            print("냉장고 재료 realm DB 저장 실패")
        }

        print(realm.configuration.fileURL)
    }

    func fetchAll(sortBy: SortOption) -> [FridgeIngredientDetail] {
        print(realm.configuration.fileURL)

        let objects = realm.objects(FridgeIngredientObject.self)
        let sorted = applySorting(to: objects, sortBy: sortBy)
        return sorted.map { FridgeIngredientDetail(from: $0) }
    }

    func fetchByCategories(_ categoryIds: [Int], sortBy: SortOption) -> [FridgeIngredientDetail] {
        let objects = realm.objects(FridgeIngredientObject.self)
            .where { $0.categoryId.in(categoryIds) }
        let sorted = applySorting(to: objects, sortBy: sortBy)
        return sorted.map { FridgeIngredientDetail(from: $0) }
    }

    func delete(_ id: String) throws {
        guard let objectId = try? ObjectId(string: id),
              let object = realm.object(ofType: FridgeIngredientObject.self, forPrimaryKey: objectId) else {
            throw NSError(domain: "FridgeIngredientDataSource", code: 404, userInfo: [NSLocalizedDescriptionKey: "Object not found"])
        }
        try realm.write {
            realm.delete(object)
        }
    }

    // MARK: - Private
    private func applySorting(to results: Results<FridgeIngredientObject>, sortBy: SortOption) -> Results<FridgeIngredientObject> {
        switch sortBy {
        case .basic:
            return results.sorted(byKeyPath: "name", ascending: true)
        case .expiryDate:
            return results.sorted(byKeyPath: "expirationDate", ascending: true)
        }
    }
}
