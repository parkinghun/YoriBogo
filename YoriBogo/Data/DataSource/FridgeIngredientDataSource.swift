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
    func fetchAll() -> [FridgeIngredientDetail]
    func delete(_ id: String) throws
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
        
    
    func fetchAll() -> [FridgeIngredientDetail] {
        print(realm.configuration.fileURL)

        let objects = realm.objects(FridgeIngredientObject.self)
        return objects.map { FridgeIngredientDetail(from: $0) }
    }
    
    func delete(_ id: String) throws {
        guard let object = realm.object(ofType: FridgeIngredientObject.self, forPrimaryKey: id) else { return }
        try realm.write {
            realm.delete(object)
        }
    }
}
