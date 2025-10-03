//
//  Recipe.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation

protocol RecipeDisplayable {
    var title: String { get }
    var category: RecipeCategory? { get }
    var method: RecipeMethod? { get }
    var tags: [String] { get }
    var tip: String? { get }
    var ingredients: [RecipeIngredient] { get }
    var steps: [RecipeStep] { get }
    var images: [RecipeImage] { get }
}

// TODO: - 북마크 기능도
struct Recipe: RecipeDisplayable {
    let id: String
    let baseId: String
    let kind: RecipeKind
    let version: Int
    
    let title: String
    let category: RecipeCategory?
    let method: RecipeMethod?
    let tags: [String]
    let tip: String?
    
    let images: [RecipeImage]
    let nutrition: RecipeNutrition?
    let ingredients: [RecipeIngredient]
    let steps: [RecipeStep]
    
    let isBookmarked: Bool
    let rating: Double?
    let cookCount: Int
    let lastCookedAt: Date?
    
    let createdAt: Date
    let updatedAt: Date?
    
}

extension Recipe {
    // 사용자 수정 버전 생성
    init(modifying original: Recipe, with changes: RecipeChanges) {
        self.id = UUID().uuidString
        self.baseId = original.baseId
        self.kind = .userModified
        self.version = original.version + 1
        
        self.title = changes.title ?? original.title
        self.category = changes.category ?? original.category
        self.method = changes.method ?? original.method
        self.tags = changes.tags ?? original.tags
        self.tip = changes.tip ?? original.tip
        
        self.images = changes.images ?? original.images
        self.nutrition = changes.nutrition ?? original.nutrition
        self.ingredients = changes.ingredients ?? original.ingredients
        self.steps = changes.steps ?? original.steps
        
        self.isBookmarked = original.isBookmarked
        self.rating = original.rating
        self.cookCount = original.cookCount
        self.lastCookedAt = original.lastCookedAt
        
        self.createdAt = Date()
        self.updatedAt = nil
    }
}

// 레시피 수정용 구조체
struct RecipeChanges {
    let title: String?
    let category: RecipeCategory?
    let method: RecipeMethod?
    let tags: [String]?
    let tip: String?
    let images: [RecipeImage]?
    let nutrition: RecipeNutrition?
    let ingredients: [RecipeIngredient]?
    let steps: [RecipeStep]?
}

enum RecipeKind: Int, CaseIterable {
    case api = 0           // API에서 가져온 원본
    case userOriginal = 1  // 사용자가 직접 만든 레시피
    case userModified = 2  // API 레시피를 사용자가 수정한 버전
}

enum RecipeImageSource: String, CaseIterable {
    case remoteURL
    case localPath
}

struct RecipeImage {
    let source: RecipeImageSource
    let value: String
    let isThumbnail: Bool
    
    init(source: RecipeImageSource, value: String, isThumbnail: Bool = false) {
        self.source = source
        self.value = value
        self.isThumbnail = isThumbnail
    }
}

struct RecipeNutrition {
    let calories: String?
    let protein: String?
    let fat: String?
    let carbs: String?
    let sodium: String?
    let weight: String?
}

struct RecipeIngredient {
    let name: String
    let qty: Double?
    let unit: String?
    let altText: String?
}

struct RecipeStep {
    let index: Int
    let text: String
    let images: [RecipeImage]
}

enum RecipeCategory: Equatable {
    case sideDish        // 반찬
    case soup            // 국&탕
    case dessert         // 디저트
    case snack           // 간식 등
    case salad           // 샐러드 등의 카테고리
    case rice            // 밥
    case noodle          // 면
    case unknown(String) // fallback
    
    init(rawValue: String) {
        switch rawValue {
        case "반찬": self = .sideDish
        case "국&탕", "국/탕", "국 탕": self = .soup
        case "디저트": self = .dessert
        case "간식": self = .snack
        case "샐러드": self = .salad
        case "밥": self = .rice
        case "면": self = .noodle
        default: self = .unknown(rawValue)
        }
    }
    
    var displayName: String {
        switch self {
        case .sideDish: return "반찬"
        case .soup: return "국/탕"
        case .dessert: return "디저트"
        case .snack: return "간식"
        case .salad: return "샐러드"
        case .rice: return "밥"
        case .noodle: return "면"
        case .unknown(let raw): return raw
        }
    }
    
    static var allCases: [RecipeCategory] {
        return [.sideDish, .soup, .dessert, .snack, .salad, .rice, .noodle]
    }
}

enum RecipeMethod: Equatable, CaseIterable {
    case boil       // 끓이기
    case steam      // 찌기
    case fry        // 튀기기
    case roast      // 굽기 / 로스트
    case stirFry    // 볶기
    case mix        // 무침 / 섞기 등
    case raw        // 생 / 무가열 조리
    case simmer     // 조리기
    case unknown(String)
    
    init(rawValue: String) {
        switch rawValue {
        case "찌기": self = .steam
        case "굽기": self = .roast
        case "튀기기": self = .fry
        case "볶기": self = .stirFry
        case "무침", "버무리기": self = .mix
        case "생": self = .raw
        case "끓이기": self = .boil
        case "조리기": self = .simmer
        default: self = .unknown(rawValue)
        }
    }
    
    var displayName: String {
        switch self {
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
    
    static var allCases: [RecipeMethod] {
        return [.boil, .steam, .roast, .fry, .stirFry, .mix, .raw, .simmer]
    }
}
