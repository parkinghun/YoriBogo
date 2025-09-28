//
//  FridgeDTO.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

struct FridgeDTO: Decodable {
    let categories: [FridgeCategoryDTO]
    let subcategories: [FridgeSubcategoryDTO]
    let ingredients: [FridgeIngredientDTO]
}

struct FridgeCategoryDTO: Decodable {
    let id: Int
    let name: String
    let imageName: String
}

struct FridgeSubcategoryDTO: Decodable {
    let id: Int
    let categoryId: Int
    let name: String
}

struct FridgeIngredientDTO: Decodable {
    let id: Int
    let key: String
    let name: String
    let categoryId: Int
    let subcategoryId: Int
}
