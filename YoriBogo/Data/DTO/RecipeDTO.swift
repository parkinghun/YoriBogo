//
//  RecipeDTO.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation

struct RecipeResponseDTO: Decodable {
    let body: RecipeListDTO
    
    enum CodingKeys: String, CodingKey {
        case body = "COOKRCP01"
    }
}

struct RecipeListDTO: Decodable {
    let totalCount: String
    let row: [RecipeDTO]
    let result: RecipeAPIResultDTO
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case row
        case result = "RESULT"
    }
}

struct RecipeAPIResultDTO: Decodable {
    let message: String
    let code: String
    
    enum CodingKeys: String, CodingKey {
        case message = "MSG"
        case code = "CODE"
    }
}

struct RecipeDTO: Decodable {
    let seq: String                 // RCP_SEQ
    let name: String                // RCP_NM
    let category: String          // RCP_PAT2 (반찬/국&탕 등)
    let method: String            // RCP_WAY2 (굽기/찌기 등)
    let hashTag: String            // HASH_TAG
    let partsDetail: String        // RCP_PARTS_DTLS (재료 문자열)
    let naTip: String             // RCP_NA_TIP (나트륨 팁 등)
    
    // 영양 정보
    let infoEng: String            // INFO_ENG (열량)
    let infoPro: String            // INFO_PRO (단백질)
    let infoFat: String            // INFO_FAT (지방)
    let infoCar: String            // INFO_CAR (탄수화물)
    let infoNa: String             // INFO_NA (나트륨)
    let infoWgt: String            // INFO_WGT (중량)
    
    let mainImage: String          // ATT_FILE_NO_MAIN
    let makingImage: String        // ATT_FILE_NO_MK
    
    // 조리 단계 (MANUAL01~20)
    let manual01: String
    let manual02: String
    let manual03: String
    let manual04: String
    let manual05: String
    let manual06: String
    let manual07: String
    let manual08: String
    let manual09: String
    let manual10: String
    let manual11: String
    let manual12: String
    let manual13: String
    let manual14: String
    let manual15: String
    let manual16: String
    let manual17: String
    let manual18: String
    let manual19: String
    let manual20: String
    
    // 조리 단계 이미지 (MANUAL_IMG01~20)
    let manualImg01: String
    let manualImg02: String
    let manualImg03: String
    let manualImg04: String
    let manualImg05: String
    let manualImg06: String
    let manualImg07: String
    let manualImg08: String
    let manualImg09: String
    let manualImg10: String
    let manualImg11: String
    let manualImg12: String
    let manualImg13: String
    let manualImg14: String
    let manualImg15: String
    let manualImg16: String
    let manualImg17: String
    let manualImg18: String
    let manualImg19: String
    let manualImg20: String
    
    enum CodingKeys: String, CodingKey {
        case seq = "RCP_SEQ"
        case name = "RCP_NM"
        case category = "RCP_PAT2"
        case method = "RCP_WAY2"
        case hashTag = "HASH_TAG"
        case partsDetail = "RCP_PARTS_DTLS"
        case naTip = "RCP_NA_TIP"
        
        case infoEng = "INFO_ENG"
        case infoPro = "INFO_PRO"
        case infoFat = "INFO_FAT"
        case infoCar = "INFO_CAR"
        case infoNa = "INFO_NA"
        case infoWgt = "INFO_WGT"
        
        case mainImage = "ATT_FILE_NO_MAIN"
        case makingImage = "ATT_FILE_NO_MK"
        
        case manual01 = "MANUAL01", manual02 = "MANUAL02", manual03 = "MANUAL03", manual04 = "MANUAL04", manual05 = "MANUAL05"
        case manual06 = "MANUAL06", manual07 = "MANUAL07", manual08 = "MANUAL08", manual09 = "MANUAL09", manual10 = "MANUAL10"
        case manual11 = "MANUAL11", manual12 = "MANUAL12", manual13 = "MANUAL13", manual14 = "MANUAL14", manual15 = "MANUAL15"
        case manual16 = "MANUAL16", manual17 = "MANUAL17", manual18 = "MANUAL18", manual19 = "MANUAL19", manual20 = "MANUAL20"
        
        case manualImg01 = "MANUAL_IMG01", manualImg02 = "MANUAL_IMG02", manualImg03 = "MANUAL_IMG03", manualImg04 = "MANUAL_IMG04"
        case manualImg05 = "MANUAL_IMG05", manualImg06 = "MANUAL_IMG06", manualImg07 = "MANUAL_IMG07", manualImg08 = "MANUAL_IMG08"
        case manualImg09 = "MANUAL_IMG09", manualImg10 = "MANUAL_IMG10", manualImg11 = "MANUAL_IMG11", manualImg12 = "MANUAL_IMG12"
        case manualImg13 = "MANUAL_IMG13", manualImg14 = "MANUAL_IMG14", manualImg15 = "MANUAL_IMG15", manualImg16 = "MANUAL_IMG16"
        case manualImg17 = "MANUAL_IMG17", manualImg18 = "MANUAL_IMG18", manualImg19 = "MANUAL_IMG19", manualImg20 = "MANUAL_IMG20"
    }
    
    // DTO 내부 헬퍼 메서드: 동적 단계 추출
    var manualSteps: [(text: String, image: String)] {
        let manuals = [manual01, manual02, manual03, manual04, manual05, manual06, manual07, manual08, manual09, manual10,
                      manual11, manual12, manual13, manual14, manual15, manual16, manual17, manual18, manual19, manual20]
        let images = [manualImg01, manualImg02, manualImg03, manualImg04, manualImg05, manualImg06, manualImg07, manualImg08, manualImg09, manualImg10,
                     manualImg11, manualImg12, manualImg13, manualImg14, manualImg15, manualImg16, manualImg17, manualImg18, manualImg19, manualImg20]
        
        return zip(manuals, images)
            .enumerated()
            .compactMap { index, step in
                let trimmedText = step.0.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedText.isEmpty ? nil : (text: trimmedText, image: step.1)
            }
    }

}

extension RecipeDTO {
    func toEntity() -> Recipe {
        return Recipe(
            id: seq,
            baseId: seq,
            kind: .api,
            version: 0,
            title: name,
            category: RecipeCategory(rawValue: category),
            method: RecipeMethod(rawValue: method),
            tags: hashTag.split(separator: ",").map { String($0) },
            tip: naTip,
            images: [
                RecipeImage(source: .remoteURL, value: mainImage, isThumbnail: true),
                RecipeImage(source: .remoteURL, value: makingImage, isThumbnail: false)
            ],
            nutrition: RecipeNutrition(
                calories: infoEng,
                protein: infoPro,
                fat: infoFat,
                carbs: infoCar,
                sodium: infoNa,
                weight: infoWgt
            ),
            ingredients: RecipeIngredientParser.parse(from: partsDetail),
            steps: RecipeStepParser.parse(from: self),
            isBookmarked: false,
            rating: nil,
            cookCount: 0,
            lastCookedAt: nil,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}
