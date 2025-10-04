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

    func save(_ ingredient: FridgeIngredientDetail) throws {
        let realm = try Realm()
        let object = ingredient.toRealmObject()

        try realm.write {
            realm.add(object, update: .modified)
        }
    }

    func fetchAll(sortBy: SortOption) -> [FridgeIngredientDetail] {
        let realm = try! Realm()
        let objects = realm.objects(FridgeIngredientObject.self)
        return applySorting(to: Array(objects), sortBy: sortBy)
    }

    func fetchByCategories(_ categoryIds: [Int], sortBy: SortOption) -> [FridgeIngredientDetail] {
        let realm = try! Realm()
        let objects = realm.objects(FridgeIngredientObject.self)
            .where { $0.categoryId.in(categoryIds) }
        return applySorting(to: Array(objects), sortBy: sortBy)
    }

    func delete(_ id: String) throws {
        let realm = try Realm()
        guard let objectId = try? ObjectId(string: id),
              let object = realm.object(ofType: FridgeIngredientObject.self, forPrimaryKey: objectId) else {
            throw NSError(domain: "FridgeIngredientDataSource", code: 404, userInfo: [NSLocalizedDescriptionKey: "Object not found"])
        }
        try realm.write {
            realm.delete(object)
        }
    }

    // MARK: - Private
    private func applySorting(to objects: [FridgeIngredientObject], sortBy: SortOption) -> [FridgeIngredientDetail] {
        let details = objects.map { FridgeIngredientDetail(from: $0) }

        switch sortBy {
        case .basic:
            return details.sorted { $0.name < $1.name }
        case .expiryDate:
            return details.sorted { lhs, rhs in
                switch (lhs.expirationDate, rhs.expirationDate) {
                case (nil, nil):
                    return false
                case (nil, _):
                    return false  // nil을 뒤로
                case (_, nil):
                    return true   // nil을 뒤로
                case (let date1?, let date2?):
                    return date1 < date2
                }
            }
        }
    }
}
