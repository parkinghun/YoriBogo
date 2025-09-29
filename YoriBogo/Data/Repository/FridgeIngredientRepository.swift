//
//  FridgeIngredientRepository.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

protocol FridgeIngredientRepositoryType {
    func addIngredient(_ ingredient: FridgeIngredientDetail) throws
    func getIngredients() -> [FridgeIngredientDetail]
    func removeIngredient(id: String) throws
    
//    func loadMockIngredients() -> [FridgeIngredientDetail]
}

final class FridgeIngredientRepository: FridgeIngredientRepositoryType {
    private let dataSource: FridgeIngredientDataSourceType

    init(dataSource: FridgeIngredientDataSourceType = FridgeIngredientDataSource()) {
        self.dataSource = dataSource
    }

    func addIngredient(_ ingredient: FridgeIngredientDetail) throws {
        try dataSource.save(ingredient)
    }

    func getIngredients() -> [FridgeIngredientDetail] {
        return dataSource.fetchAll()
    }

    func removeIngredient(id: String) throws {
        try dataSource.delete(id)
    }
    
    func getFridgeEntities() -> ([FridgeCategory], [FridgeSubcategory], [FridgeIngredient]) {
        let dto = Bundle.loadJSON("FridgeIngredients", as: FridgeDTO.self)
        
        let categories = dto.categories.map { FridgeCategory(from: $0) }
        let subcategories = dto.subcategories.map { FridgeSubcategory(from: $0) }
        let ingredients = dto.ingredients.map { FridgeIngredient(from: $0) }
        
        return (categories, subcategories, ingredients)
    }
//    func loadMockIngredients() -> [FridgeIngredientDetail] {
//        guard let dto = MockLoader.loadFridgeDTO() else { return [] }
//        let baseIngredients = FridgeIngredientConverter.toEntities(from: dto).ingredients
//        
//        return baseIngredients.map {
//            FridgeIngredientDetail(from: $0, qty: 1, unit: "개", altText: nil, expirationDate: Date().addingTimeInterval(60*60*24*7))
//        }
//    }
}
