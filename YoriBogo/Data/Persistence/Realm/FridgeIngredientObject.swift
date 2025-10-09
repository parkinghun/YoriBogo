//
//  FridgeIngredientObject.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation
import RealmSwift

final class FridgeIngredientObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String  // 재료명
    @Persisted var categoryId: Int  // 카테고리(0: 채소 ..)
    @Persisted var subcategoryId: Int?
    @Persisted var imageKey: String // 이모지 asset 이름
    
    @Persisted var qty: Double?  // 수량
    @Persisted var unit: String?  // 단위
    @Persisted var altText: String?  // 보조 표기
    @Persisted var expirationDate: Date?  // 소비기한
    @Persisted var regDate: Date  // 등록일
    @Persisted var updatedAt: Date?  // 수정일
    @Persisted var notifyD3: Bool  // 알림 전송 여부 D-3
    @Persisted var notifyD1: Bool  // 알림 전송 여부 D-1
    @Persisted var notifyDday: Bool  // 알림 전송 여부 D-day
    
    convenience init(from entity: FridgeIngredientDetail) {
        self.init()

        // 기존 ObjectId가 있으면 사용 (수정 시), 없으면 새로 생성 (추가 시)
        if let objectId = try? ObjectId(string: entity.id) {
            self.id = objectId
        }

        self.name = entity.name
        self.categoryId = entity.categoryId
        self.subcategoryId = entity.subcategoryId
        self.imageKey = entity.imageKey

        self.qty = entity.qty
        self.unit = entity.unit
        self.altText = entity.altText
        self.expirationDate = entity.expirationDate
        self.regDate = entity.regDate
        self.updatedAt = entity.updatedAt
        self.notifyD3 = entity.notifyD3
        self.notifyD1 = entity.notifyD1
        self.notifyDday = entity.notifyDday
    }
    
    func toEntity() -> FridgeIngredientDetail {
        return FridgeIngredientDetail(from: self)
    }
}


