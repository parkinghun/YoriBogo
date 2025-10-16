//
//  RecipeAddViewController+DataLoading.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-15.
//

import UIKit
import Kingfisher

// MARK: - Data Loading & Change Detection
extension RecipeAddViewController {

    func loadRecipeData() {
        guard let recipe = editingRecipe else { return }

        titleTextField.text = recipe.title
        loadMainImages(from: recipe.images)

        if let category = recipe.category {
            categoryButton.setTitle(category.displayName, for: .normal)
        }

        tags = recipe.tags
        updateTagChips()

        if let tip = recipe.tip, !tip.isEmpty {
            tipTextView.text = tip
            tipTextView.textColor = .black
        }

        loadIngredients(recipe.ingredients)
        loadSteps(recipe.steps)

        setupChangeDetection()
    }

    func loadMainImages(from recipeImages: [RecipeImage]) {
        guard !recipeImages.isEmpty else { return }

        // 원본 이미지 경로 저장
        originalMainImagePaths = recipeImages.map { $0.value }

        let group = DispatchGroup()
        var loadedImages: [(index: Int, image: UIImage)] = []

        for (index, recipeImage) in recipeImages.enumerated() {
            group.enter()

            switch recipeImage.source {
            case .remoteURL:
                // HTTP -> HTTPS 변환
                let httpsURLString = recipeImage.value.replacingOccurrences(of: "http://", with: "https://")

                // URL에서 이미지 다운로드
                guard let url = URL(string: httpsURLString) else {
                    group.leave()
                    continue
                }

                KingfisherManager.shared.retrieveImage(with: url) { result in
                    switch result {
                    case .success(let imageResult):
                        loadedImages.append((index, imageResult.image))
                    case .failure(let error):
                        print("❌ 이미지 다운로드 실패: \(error)")
                    }
                    group.leave()
                }

            case .localPath:
                // 로컬 파일에서 이미지 로드 (파일 존재 확인 포함)
                if let image = ImagePathHelper.shared.loadImage(at: recipeImage.value) {
                    loadedImages.append((index, image))
                } else {
                    print("⚠️ 이미지 파일을 찾을 수 없음: \(recipeImage.value)")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // 인덱스 순서대로 정렬
            loadedImages.sort { $0.index < $1.index }

            // 이미지를 임시 캐시에 저장하고 경로 반환
            self.mainImagePaths = loadedImages.map { _, image in
                ImageCacheHelper.shared.cacheTempImage(image)
            }

            self.updateMainImageDisplay()
        }
    }

    func setupChangeDetection() {
        titleTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        tagTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc func textFieldDidChange() {
        checkForChanges()
    }

    func checkForChanges() {
        guard isEditMode, let original = originalRecipeSnapshot else { return }

        // 타이틀 변경 확인
        let titleChanged = titleTextField.text?.trimmingCharacters(in: .whitespaces) != original.title

        // 카테고리 변경 확인
        let currentCategory = RecipeCategory(rawValue: categoryButton.titleLabel?.text ?? "한식")
        let categoryChanged = currentCategory.displayName != original.category?.displayName

        // 태그 변경 확인
        let tagsChanged = tags != original.tags

        // 메인 이미지 개수 변경 확인
        let mainImagesChanged = mainImagePaths.count != original.images.count

        // 재료 변경 확인 (개수 및 내용)
        let currentIngredients = collectIngredients()
        let ingredientsChanged = !areIngredientsEqual(currentIngredients, original.ingredients)

        // 단계 변경 확인 (개수 및 내용)
        let currentSteps = collectSteps()
        let stepsChanged = !areStepsEqual(currentSteps, original.steps)

        // 요리 팁 변경 확인
        let currentTip = (tipTextView.textColor == .gray400 || tipTextView.text.isEmpty) ? nil : tipTextView.text
        let tipChanged = currentTip != original.tip

        // 하나라도 변경되었으면 저장 버튼 활성화
        let hasChanges = titleChanged || categoryChanged || tagsChanged || mainImagesChanged ||
                         ingredientsChanged || stepsChanged || tipChanged

        saveButton.isEnabled = hasChanges
    }

    // MARK: - Helper Methods for Change Detection

    private func areIngredientsEqual(_ ingredients1: [RecipeIngredient], _ ingredients2: [RecipeIngredient]) -> Bool {
        guard ingredients1.count == ingredients2.count else { return false }

        for (index, ingredient1) in ingredients1.enumerated() {
            let ingredient2 = ingredients2[index]

            if ingredient1.name != ingredient2.name ||
               ingredient1.qty != ingredient2.qty ||
               ingredient1.unit != ingredient2.unit {
                return false
            }
        }

        return true
    }

    private func areStepsEqual(_ steps1: [RecipeStep], _ steps2: [RecipeStep]) -> Bool {
        guard steps1.count == steps2.count else { return false }

        for (index, step1) in steps1.enumerated() {
            let step2 = steps2[index]

            // 텍스트와 이미지 개수 비교
            if step1.text != step2.text ||
               step1.images.count != step2.images.count {
                return false
            }
        }

        return true
    }

    func saveMainImagesToLocal() -> [RecipeImage] {
        var recipeImages: [RecipeImage] = []

        // API 레시피로부터 만들기인 경우, 모든 이미지를 새로 저장
        if isCreateFromApi {
            for (index, imagePath) in mainImagePaths.enumerated() {
                // 경로에서 이미지 로드 (임시 캐시 또는 파일)
                guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                    continue
                }

                if let savedPath = saveImageToLocal(image: image, prefix: "main", index: index) {
                    let recipeImage = RecipeImage(
                        source: .localPath,
                        value: savedPath,
                        isThumbnail: index == 0
                    )
                    recipeImages.append(recipeImage)
                }
            }
            return recipeImages
        }

        // 일반 편집 모드: 기존 이미지는 재사용, 새 이미지만 저장
        for (index, imagePath) in mainImagePaths.enumerated() {
            // 기존 이미지인지 확인 (originalMainImagePaths와 같은 인덱스에 있으면 기존 이미지)
            if index < originalMainImagePaths.count {
                // 기존 이미지 경로 재사용
                let recipeImage = RecipeImage(
                    source: .localPath,
                    value: originalMainImagePaths[index],
                    isThumbnail: index == 0
                )
                recipeImages.append(recipeImage)
            } else {
                // 새로운 이미지 저장 (임시 캐시에서 로드)
                guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                    continue
                }

                if let savedPath = saveImageToLocal(image: image, prefix: "main", index: index) {
                    let recipeImage = RecipeImage(
                        source: .localPath,
                        value: savedPath,
                        isThumbnail: index == 0
                    )
                    recipeImages.append(recipeImage)
                }
            }
        }

        // 삭제된 이미지 처리 (originalMainImagePaths보다 mainImagePaths가 적으면)
        if mainImagePaths.count < originalMainImagePaths.count {
            for index in mainImagePaths.count..<originalMainImagePaths.count {
                deleteImageFile(at: originalMainImagePaths[index])
            }
        }

        return recipeImages
    }

    func deleteImageFile(at path: String) {
        ImagePathHelper.shared.deleteImage(at: path)
    }

    func saveImageToLocal(image: UIImage, stepNumber: Int, imageIndex: Int) -> String? {
        return saveImageToLocal(image: image, prefix: "step_\(stepNumber)", index: imageIndex)
    }

    func saveImageToLocal(image: UIImage, prefix: String, index: Int) -> String? {
        // 중복 체크를 포함한 이미지 저장 (같은 이미지가 있으면 재사용)
        return ImagePathHelper.shared.saveImageWithDuplicateCheck(image, prefix: prefix, index: index)
    }
}
