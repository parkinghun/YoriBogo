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
                // 로컬 파일에서 이미지 로드
                if let image = UIImage(contentsOfFile: recipeImage.value) {
                    loadedImages.append((index, image))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // 인덱스 순서대로 정렬
            loadedImages.sort { $0.index < $1.index }
            self.mainImages = loadedImages.map { $0.image }
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

        let hasChanges = titleTextField.text?.trimmingCharacters(in: .whitespaces) != original.title ||
                         tags != original.tags ||
                         ingredientsStackView.arrangedSubviews.count != original.ingredients.count ||
                         stepsStackView.arrangedSubviews.count != original.steps.count ||
                         mainImages.count != original.images.count

        saveButton.isEnabled = hasChanges
    }

    func saveMainImagesToLocal() -> [RecipeImage] {
        var recipeImages: [RecipeImage] = []

        // 이미지별로 처리
        for (index, image) in mainImages.enumerated() {
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
                // 새로운 이미지 저장
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

        // 삭제된 이미지 처리 (originalMainImagePaths보다 mainImages가 적으면)
        if mainImages.count < originalMainImagePaths.count {
            for index in mainImages.count..<originalMainImagePaths.count {
                deleteImageFile(at: originalMainImagePaths[index])
            }
        }

        return recipeImages
    }

    func deleteImageFile(at path: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
                print("✅ 이미지 삭제 성공: \(path)")
            } catch {
                print("❌ 이미지 삭제 실패: \(error)")
            }
        }
    }

    func saveImageToLocal(image: UIImage, stepNumber: Int, imageIndex: Int) -> String? {
        return saveImageToLocal(image: image, prefix: "step_\(stepNumber)", index: imageIndex)
    }

    func saveImageToLocal(image: UIImage, prefix: String, index: Int) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let recipeImagesDirectory = documentsDirectory.appendingPathComponent("RecipeImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: recipeImagesDirectory, withIntermediateDirectories: true)

        let fileName = "\(prefix)_\(index)_\(UUID().uuidString).jpg"
        let fileURL = recipeImagesDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("❌ 이미지 저장 실패: \(error)")
            return nil
        }
    }
}
