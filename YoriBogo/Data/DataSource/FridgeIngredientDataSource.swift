//
//  FridgeIngredientDataSource.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation
import RealmSwift

extension Notification.Name {
    static let fridgeIngredientsDidChange = Notification.Name("fridgeIngredientsDidChange")
}

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

    private let notificationService = NotificationService.shared

    func save(_ ingredient: FridgeIngredientDetail) throws {
        let realm = try Realm()
        let object = ingredient.toRealmObject()

        // 수정인지 추가인지 확인 (기존 객체 존재 여부)
        let isUpdate = realm.object(ofType: FridgeIngredientObject.self, forPrimaryKey: object.id) != nil

        try realm.write {
            realm.add(object, update: .modified)
        }

        // 소비기한 알림 스케줄링
        if let _ = ingredient.expirationDate {
            if isUpdate {
                // 수정: 기존 알림 삭제 후 재등록
                notificationService.updateExpiryNotifications(for: ingredient)
            } else {
                // 추가: 새 알림 등록
                notificationService.scheduleExpiryNotifications(for: ingredient)
            }
        } else {
            // 소비기한이 없으면 기존 알림 삭제
            notificationService.removeExpiryNotifications(for: ingredient)
        }

        // 냉장고 재료 변경 알림
        NotificationCenter.default.post(name: .fridgeIngredientsDidChange, object: nil)
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

        // 삭제 전에 재료 정보를 저장 (알림 삭제용)
        let ingredient = FridgeIngredientDetail(from: object)

        try realm.write {
            realm.delete(object)
        }

        // 소비기한 알림 삭제
        notificationService.removeExpiryNotifications(for: ingredient)

        // 냉장고 재료 변경 알림
        NotificationCenter.default.post(name: .fridgeIngredientsDidChange, object: nil)
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
