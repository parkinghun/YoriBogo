//
//  FridgeIngredientRepository.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

protocol FridgeIngredientRepositoryType {
    func addIngredient(_ ingredient: FridgeIngredientDetail) throws
    func getIngredients(sortBy: SortOption) -> [FridgeIngredientDetail]
    func getIngredients(byCategoryIds categoryIds: [Int], sortBy: SortOption) -> [FridgeIngredientDetail]
    func removeIngredient(id: String) throws
}

final class FridgeIngredientRepository: FridgeIngredientRepositoryType {
    private let dataSource: FridgeIngredientDataSourceType

    init(dataSource: FridgeIngredientDataSourceType = FridgeIngredientDataSource()) {
        self.dataSource = dataSource
    }

    func addIngredient(_ ingredient: FridgeIngredientDetail) throws {
        try dataSource.save(ingredient)
    }

    func getIngredients(sortBy: SortOption = .basic) -> [FridgeIngredientDetail] {
        return dataSource.fetchAll(sortBy: sortBy)
    }

    func getIngredients(byCategoryIds categoryIds: [Int], sortBy: SortOption = .basic) -> [FridgeIngredientDetail] {
        return dataSource.fetchByCategories(categoryIds, sortBy: sortBy)
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
    
    func getCategoryName(for categoryId: Int) -> String {
        let (categories, _, _) = getFridgeEntities()
        return categories.first { $0.id == categoryId}?.name ?? "기타"
    }
}
