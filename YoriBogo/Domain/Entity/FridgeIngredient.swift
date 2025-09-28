//
//  FridgeIngredient.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

struct FridgeCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let imageName: String
    
    init(from dto: FridgeCategoryDTO) {
        self.id = dto.id
        self.name = dto.name
        self.imageName = dto.imageName
    }
}

struct FridgeSubcategory: Identifiable, Hashable {
    let id: Int
    let categoryId: Int
    let name: String
    
    init(from dto: FridgeSubcategoryDTO) {
        self.id = dto.id
        self.categoryId = dto.categoryId
        self.name = dto.name
    }
}

// UI 보여주는용
struct FridgeIngredient: Identifiable, Hashable {
    let id: Int
    let key: String   // 이미지 매핑용
    let name: String
    let categoryId: Int
    let subcategoryId: Int
    
    init(from dto: FridgeIngredientDTO) {
        self.id = dto.id
        self.key = dto.key   // 이미지 매핑용
        self.name = dto.name
        self.categoryId = dto.categoryId
        self.subcategoryId = dto.subcategoryId
    }
}

// DB 저장용
struct FridgeIngredientDetail {
    let id: String
    let name: String
    let categoryId: Int
    let subcategoryId: Int?
    let imageKey: String   // 이미지 매핑용

    // 사용자 입력/상태
    var qty: Double?
    var unit: String?
    var altText: String?  // 보조 표기(1/2개 등..)
    var expirationDate: Date?  // 소비기한
    var regDate: Date  // 등록일
    var updatedAt: Date?  // 수정일
    var notifyD3: Bool // 알림 전송 여부 D-3
    var notifyD1: Bool  // 알림 전송 여부 D-1
    var notifyDday: Bool  // 알림 전송 여부 D-day
    
    init(from base: FridgeIngredient, qty: Double, unit: String?, altText: String?, expirationDate: Date?, notifyD3: Bool = false, notifyD1: Bool = false, notifyDday: Bool = false) {
        self.id = "\(base.id)"
        self.name = base.name
        self.categoryId = base.categoryId
        self.subcategoryId = base.subcategoryId
        self.imageKey = base.key
        self.qty = qty
        self.unit = unit
        self.altText = altText
        self.expirationDate = expirationDate
        self.regDate = Date()
        self.updatedAt = nil
        self.notifyD3 = notifyD3
        self.notifyD1 = notifyD1
        self.notifyDday = notifyDday
    }
    
    init(from object: FridgeIngredientObject) {
        self.id = object.id.stringValue
        self.name = object.name
        self.categoryId = object.categoryId
        self.subcategoryId = object.subcategoryId
        self.imageKey = object.imageKey
        self.qty = object.qty
        self.unit = object.unit
        self.altText = object.altText
        self.expirationDate = object.expirationDate
        self.regDate = object.regDate
        self.updatedAt = object.updatedAt
        self.notifyD3 = object.notifyD3
        self.notifyD1 = object.notifyD1
        self.notifyDday = object.notifyDday
    }
}

extension FridgeIngredientDetail {
    func toRealmObject() -> FridgeIngredientObject {
        FridgeIngredientObject(from: self)
    }
}
