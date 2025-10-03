//
//  RecipeObject.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import RealmSwift

final class RecipeObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    
    // 원본/공유 식별자
    @Persisted var baseId: String   // API RCP_SEQ or UUID
    @Persisted var kind: Int        // RecipeKind.rawValue
    @Persisted var version: Int     // 0=원본, 1…N=사용자 버전
    
    // 기본 정보
    @Persisted var title: String
    @Persisted var category: String?
    @Persisted var method: String?
    @Persisted var tags: List<String>  // 해시태그
    @Persisted var tip: String?
    
    // 대표이미지
    @Persisted var images: List<RecipeImageObject>
    
    // 영양 정보
    @Persisted var nutrition: RecipeNutritionObject?
    
    // 재료 & 단계
    @Persisted var ingredients = List<RecipeIngredientObject>()
    @Persisted var steps = List<RecipeStepObject>()
    
    // 유저 메타 정보
    @Persisted var isBookmarked: Bool
    @Persisted var rating: Double
    @Persisted var cookCount: Int
    @Persisted var lastCookedAt: Date?
    
    // 검색/관리용
    @Persisted var searchText: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date?
    
    // Entity -> Realm Object
    convenience init(from entity: Recipe) {
        self.init()
        self.id = entity.id
        self.baseId = entity.baseId
        self.kind = entity.kind.rawValue
        self.version = entity.version

        self.title = entity.title
        // rawValue를 저장 (displayName이 아닌 원본 값)
        self.category = entity.category.flatMap { cat -> String? in
            switch cat {
            case .sideDish: return "반찬"
            case .soup: return "국&탕"
            case .dessert: return "디저트"
            case .snack: return "간식"
            case .salad: return "샐러드"
            case .rice: return "밥"
            case .noodle: return "면"
            case .unknown(let raw): return raw
            }
        }
        self.method = entity.method.flatMap { meth -> String? in
            switch meth {
            case .boil: return "끓이기"
            case .steam: return "찌기"
            case .roast: return "굽기"
            case .fry: return "튀기기"
            case .stirFry: return "볶기"
            case .mix: return "무침"
            case .raw: return "생"
            case .simmer: return "조리기"
            case .unknown(let raw): return raw
            }
        }
        self.tags.append(objectsIn: entity.tags)
        self.tip = entity.tip

        self.images.append(objectsIn: entity.images.map { RecipeImageObject(from: $0) })

        // 영양정보
        if let nutrition = entity.nutrition {
            self.nutrition = RecipeNutritionObject(from: nutrition)
        }

        // 재료 변환
        self.ingredients.append(objectsIn: entity.ingredients.map { RecipeIngredientObject(from: $0) })

        // 단계 변환
        self.steps.append(objectsIn: entity.steps.map { RecipeStepObject(from: $0) })

        // 사용자 메타
        self.isBookmarked = entity.isBookmarked
        self.rating = entity.rating ?? 0.0
        self.cookCount = entity.cookCount
        self.lastCookedAt = entity.lastCookedAt

        // 검색용 텍스트 생성
        self.searchText = "\(entity.title) \(entity.tags.joined(separator: " ")) \(entity.ingredients.map(\.name).joined(separator: " "))"
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    // Realm Object → Entity 변환
    func toEntity() -> Recipe {
           return Recipe(
               id: self.id,
               baseId: self.baseId,
               kind: RecipeKind(rawValue: self.kind) ?? .api,
               version: self.version,
               title: self.title,
               category: self.category.map { RecipeCategory(rawValue: $0) },
               method: self.method.map { RecipeMethod(rawValue: $0) },
               tags: Array(self.tags),
               tip: self.tip,
               images: self.images.map { $0.toEntity() },
               nutrition: self.nutrition?.toEntity(),
               ingredients: self.ingredients.map { $0.toEntity() },
               steps: self.steps.map { $0.toEntity() },
               isBookmarked: self.isBookmarked,
               rating: self.rating == 0.0 ? nil : self.rating,
               cookCount: self.cookCount,
               lastCookedAt: self.lastCookedAt,
               createdAt: self.createdAt,
               updatedAt: self.updatedAt
           )
       }
}

enum RecipeImageObjectSource: String, PersistableEnum {
    case remoteURL = "remote"
    case localPath = "local"
}

final class RecipeImageObject: EmbeddedObject {
    @Persisted var source: RecipeImageObjectSource
    @Persisted var value: String
    @Persisted var isThumbnail: Bool
    
    convenience init(from entity: RecipeImage) {
        self.init()
        self.source = entity.source == .remoteURL ? .remoteURL : .localPath
        self.value = entity.value
        self.isThumbnail = entity.isThumbnail
    }
    
    func toEntity() -> RecipeImage {
        return RecipeImage(
            source: self.source == .remoteURL ? .remoteURL : .localPath,
            value: self.value,
            isThumbnail: self.isThumbnail
        )
    }
}

// MARK: - 영양 정보
final class RecipeNutritionObject: EmbeddedObject {
    @Persisted var calories: String?   // INFO_ENG
    @Persisted var protein: String?    // INFO_PRO
    @Persisted var fat: String?        // INFO_FAT
    @Persisted var carbs: String?      // INFO_CAR
    @Persisted var sodium: String?     // INFO_NA
    @Persisted var weight: String?     // INFO_WGT
    
    convenience init(from entity: RecipeNutrition) {
        self.init()
        self.calories = entity.calories
        self.protein = entity.protein
        self.fat = entity.fat
        self.carbs = entity.carbs
        self.sodium = entity.sodium
        self.weight = entity.weight
    }
    
    func toEntity() -> RecipeNutrition {
        return RecipeNutrition(
            calories: self.calories,
            protein: self.protein,
            fat: self.fat,
            carbs: self.carbs,
            sodium: self.sodium,
            weight: self.weight
        )
    }
}

// MARK: - 재료
final class RecipeIngredientObject: EmbeddedObject {
    @Persisted var name: String       // 재료명 (호박잎)
    @Persisted var qty: Double        // 수량 (5) - 0이면 nil로 간주
    @Persisted var unit: String?      // 단위 (장, g, 개...)
    @Persisted var altText: String?   // 보조 정보 (가슴살, 3알 등)

    convenience init(from entity: RecipeIngredient) {
        self.init()
        self.name = entity.name
        self.qty = entity.qty ?? 0.0
        self.unit = entity.unit
        self.altText = entity.altText
    }

    func toEntity() -> RecipeIngredient {
        return RecipeIngredient(
            name: self.name,
            qty: self.qty == 0.0 ? nil : self.qty,
            unit: self.unit,
            altText: self.altText
        )
    }
}

// MARK: - 단계
final class RecipeStepObject: EmbeddedObject {
    @Persisted var index: Int
    @Persisted var text: String
    @Persisted var images: List<RecipeImageObject>
    
    convenience init(from entity: RecipeStep) {
         self.init()
         self.index = entity.index
         self.text = entity.text
         self.images.append(objectsIn: entity.images.map { RecipeImageObject(from: $0) })
     }
     
     func toEntity() -> RecipeStep {
         return RecipeStep(
             index: self.index,
             text: self.text,
             images: self.images.map { $0.toEntity() }
         )
     }
}

