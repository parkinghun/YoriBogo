//
//  RecipeAddViewController+DataLoading.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-15.
//

import UIKit

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

        for recipeImage in recipeImages {
            if let image = UIImage(contentsOfFile: recipeImage.value) {
                mainImages.append(image)
            }
        }

        updateMainImageDisplay()
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

        for (index, image) in mainImages.enumerated() {
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
