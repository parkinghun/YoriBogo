//
//  RecipeParser.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation

enum RecipeIngredientParser {
    static func parse(from partsDetail: String) -> [RecipeIngredient] {
        return partsDetail
            .split(separator: ",")
            .compactMap { raw in
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }

                // 괄호가 있는 경우 분리: "닭고기(가슴살, 120g)"
                if let openParenIndex = trimmed.firstIndex(of: "("),
                   let closeParenIndex = trimmed.lastIndex(of: ")") {
                    let name = String(trimmed[..<openParenIndex]).trimmingCharacters(in: .whitespaces)
                    let detail = String(trimmed[trimmed.index(after: openParenIndex)..<closeParenIndex])
                    return RecipeIngredient(name: name, qty: nil, unit: nil, altText: detail)
                } else {
                    // 괄호 없으면 공백으로 분리
                    let components = trimmed.components(separatedBy: " ")
                    let name = components.first ?? trimmed
                    let altText = components.count > 1 ? components.dropFirst().joined(separator: " ") : nil
                    return RecipeIngredient(name: name, qty: nil, unit: nil, altText: altText)
                }
            }
    }
}

enum RecipeStepParser {
    static func parse(from dto: RecipeDTO) -> [RecipeStep] {
        return dto.manualSteps.enumerated().map { index, step in
            let stepImages = step.image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? []
                : [RecipeImage(source: .remoteURL, value: step.image, isThumbnail: false)]
            return RecipeStep(index: index + 1, text: step.text, images: stepImages)
        }
    }
}
