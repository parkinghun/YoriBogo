//
//  RecipeParser.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation

enum RecipeIngredientParser {
    static func parse(from partsDetail: String) -> [RecipeIngredient] {
        // "●주재료 :", "●양념 :" 같은 카테고리 라벨 제거
        let cleanedText = removeCategoryHeaders(from: partsDetail)

        return cleanedText
            .split(separator: ",")
            .compactMap { raw in
                var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }

                // 개별 재료에서도 카테고리 라벨 제거 (혹시 모를 경우 대비)
                trimmed = removeCategoryLabel(from: trimmed)

                return parseIngredient(from: trimmed)
            }
    }

    // 개별 재료 파싱: "딸기 100g", "깐 마늘 5g(1작은술)", "딸기(100g)" 등
    private static func parseIngredient(from text: String) -> RecipeIngredient {
        var workingText = text
        var altText: String?
        var qty: Double?
        var unit: String?

        // 1. 괄호가 있으면 먼저 분리
        if let openParenIndex = workingText.firstIndex(of: "("),
           let closeParenIndex = workingText.lastIndex(of: ")") {
            let parenContent = String(workingText[workingText.index(after: openParenIndex)..<closeParenIndex])
            workingText = String(workingText[..<openParenIndex]).trimmingCharacters(in: .whitespaces)

            // 괄호 안의 내용이 숫자+단위 패턴이면 qty/unit으로 파싱
            if let (parsedQty, parsedUnit) = parseQuantityAndUnit(from: parenContent) {
                qty = parsedQty
                unit = parsedUnit
            } else {
                altText = parenContent
            }
        }

        // 2. workingText에서 숫자+단위 패턴 찾기: "딸기 100g" → name: "딸기", qty: 100, unit: "g"
        let pattern = "^(.+?)\\s+(\\d+\\.?\\d*)([a-zA-Zㄱ-ㅎㅏ-ㅣ가-힣]+)$"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: workingText, range: NSRange(workingText.startIndex..., in: workingText)) {

            if let nameRange = Range(match.range(at: 1), in: workingText),
               let qtyRange = Range(match.range(at: 2), in: workingText),
               let unitRange = Range(match.range(at: 3), in: workingText) {

                let name = String(workingText[nameRange]).trimmingCharacters(in: .whitespaces)
                let qtyString = String(workingText[qtyRange])
                let parsedUnit = String(workingText[unitRange])

                // 괄호에서 파싱된 값이 없으면 여기서 파싱된 값 사용
                return RecipeIngredient(
                    name: name,
                    qty: qty ?? Double(qtyString),
                    unit: unit ?? parsedUnit,
                    altText: altText
                )
            }
        }

        // 3. 숫자+단위 패턴이 없으면 그냥 이름으로 처리
        return RecipeIngredient(name: workingText, qty: qty, unit: unit, altText: altText)
    }

    // 숫자+단위 패턴 파싱 헬퍼: "100g" → (100, "g")
    private static func parseQuantityAndUnit(from text: String) -> (Double, String)? {
        let pattern = "^(\\d+\\.?\\d*)([a-zA-Zㄱ-ㅎㅏ-ㅣ가-힣]+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let qtyRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let qtyString = String(text[qtyRange])
        let unit = String(text[unitRange])

        guard let qty = Double(qtyString) else { return nil }
        return (qty, unit)
    }

    // "●주재료 : ... \n●양념 : ..." 같은 헤더 제거
    private static func removeCategoryHeaders(from text: String) -> String {
        // 줄바꿈 기준으로 분리하여 카테고리 헤더 제거
        let lines = text.components(separatedBy: "\n")
        var cleanedLines: [String] = []

        for line in lines {
            var cleanedLine = line
            // "●주재료 :", "●양념 :", "● 주재료 :", "●양념재료 :" 등 제거
            let headerPattern = "^[●■◆▶]?\\s*[가-힣]+\\s*:\\s*"
            if let regex = try? NSRegularExpression(pattern: headerPattern) {
                let range = NSRange(cleanedLine.startIndex..., in: cleanedLine)
                cleanedLine = regex.stringByReplacingMatches(in: cleanedLine, range: range, withTemplate: "")
            }

            if !cleanedLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cleanedLines.append(cleanedLine)
            }
        }

        return cleanedLines.joined(separator: ", ")
    }

    private static func removeCategoryLabel(from text: String) -> String {
        let patterns = [
            "^주재료:\\s*",
            "^핵심재료:\\s*",
            "^부재료:\\s*",
            "^양념재료:\\s*",
            "^소스재료:\\s*",
            "^재료:\\s*",
            "^기타재료:\\s*",
            "^양념:\\s*"
        ]

        var result = text
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
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
