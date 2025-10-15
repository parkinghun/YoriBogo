//
//  RecipeAddViewController+Step.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-15.
//

import UIKit
import SnapKit

// MARK: - Step Management
extension RecipeAddViewController {

    func addInitialStep() {
        let stepView = createStepView(stepNumber: 1)
        stepsStackView.addArrangedSubview(stepView)
    }

    func createStepView(stepNumber: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .gray50
        containerView.layer.cornerRadius = 16
        containerView.tag = stepNumber

        let numberLabel = UILabel()
        numberLabel.text = "\(stepNumber)"
        numberLabel.font = .systemFont(ofSize: 20, weight: .bold)
        numberLabel.textColor = .brandOrange500
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = .brandOrange50
        numberLabel.layer.cornerRadius = 20
        numberLabel.clipsToBounds = true

        let stepTextField = UITextField()
        stepTextField.placeholder = "요리 단계를 입력하세요"
        stepTextField.font = .systemFont(ofSize: 16)
        stepTextField.borderStyle = .none
        stepTextField.tag = 1000 + stepNumber

        let imageLabel = UILabel()
        imageLabel.text = "단계 이미지 (선택사항)"
        imageLabel.font = .systemFont(ofSize: 14)
        imageLabel.textColor = .gray600

        let addImageButton = UIButton()
        addImageButton.setTitle("+ 이미지 추가", for: .normal)
        addImageButton.setTitleColor(.brandOrange500, for: .normal)
        addImageButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        addImageButton.setImage(UIImage(systemName: "photo"), for: .normal)
        addImageButton.tintColor = .brandOrange500
        addImageButton.contentHorizontalAlignment = .leading
        addImageButton.semanticContentAttribute = .forceLeftToRight
        addImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        addImageButton.tag = stepNumber
        addImageButton.addTarget(self, action: #selector(addImageButtonTapped(_:)), for: .touchUpInside)

        let imageScrollView = UIScrollView()
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.tag = 2000 + stepNumber

        let imageStackView = UIStackView()
        imageStackView.axis = .horizontal
        imageStackView.spacing = 8
        imageStackView.alignment = .leading
        imageStackView.distribution = .fillEqually
        imageStackView.tag = 3000 + stepNumber

        imageScrollView.addSubview(imageStackView)
        imageStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        containerView.addSubview(numberLabel)
        containerView.addSubview(stepTextField)
        containerView.addSubview(imageLabel)
        containerView.addSubview(addImageButton)
        containerView.addSubview(imageScrollView)

        numberLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
            $0.size.equalTo(40)
        }

        stepTextField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalTo(numberLabel.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }

        imageLabel.snp.makeConstraints {
            $0.top.equalTo(stepTextField.snp.bottom).offset(16)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
        }

        addImageButton.snp.makeConstraints {
            $0.top.equalTo(imageLabel.snp.bottom).offset(8)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(32)
        }

        imageScrollView.snp.makeConstraints {
            $0.top.equalTo(addImageButton.snp.bottom).offset(12)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(0)
        }

        return containerView
    }

    @objc func addImageButtonTapped(_ sender: UIButton) {
        let stepNumber = sender.tag

        let currentImageCount = stepImages[stepNumber]?.count ?? 0
        let remainingCount = 5 - currentImageCount

        guard remainingCount > 0 else {
            showAlert(message: "이미지는 최대 5장까지 추가할 수 있습니다")
            return
        }

        imagePickerManager.presentImagePicker(
            from: self,
            maxSelectionCount: remainingCount
        ) { [weak self] images in
            self?.addImagesToStep(stepNumber: stepNumber, images: images)
        }
    }

    func addImagesToStep(stepNumber: Int, images: [UIImage]) {
        var currentImages = stepImages[stepNumber] ?? []
        currentImages.append(contentsOf: images)
        stepImages[stepNumber] = currentImages

        updateStepImagesDisplay(stepNumber: stepNumber)
        checkForChanges()
    }

    func updateStepImagesDisplay(stepNumber: Int) {
        guard let images = stepImages[stepNumber],
              !images.isEmpty else {
            if let scrollView = view.viewWithTag(2000 + stepNumber) {
                scrollView.snp.updateConstraints {
                    $0.height.equalTo(0)
                }
            }
            return
        }

        guard let stackView = view.viewWithTag(3000 + stepNumber) as? UIStackView else { return }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, image) in images.enumerated() {
            let imageContainer = UIView()

            let imageView = UIImageView()
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.backgroundColor = .systemGray6

            let deleteButton = UIButton()
            deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            deleteButton.tintColor = .white
            deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            deleteButton.layer.cornerRadius = 12
            deleteButton.tag = index
            deleteButton.addTarget(self, action: #selector(deleteImageButtonTapped(_:)), for: .touchUpInside)

            imageContainer.addSubview(imageView)
            imageContainer.addSubview(deleteButton)

            imageView.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.width.equalTo(100)
                $0.height.equalTo(100)
            }

            deleteButton.snp.makeConstraints {
                $0.top.trailing.equalToSuperview().inset(4)
                $0.size.equalTo(24)
            }

            imageContainer.tag = stepNumber * 10000 + index
            stackView.addArrangedSubview(imageContainer)
        }

        if let scrollView = view.viewWithTag(2000 + stepNumber) {
            scrollView.snp.updateConstraints {
                $0.height.equalTo(100)
            }
        }
    }

    @objc func deleteImageButtonTapped(_ sender: UIButton) {
        guard let container = sender.superview,
              let stackView = container.superview as? UIStackView else { return }

        let stepNumber = container.tag / 10000
        let imageIndex = sender.tag

        stepImages[stepNumber]?.remove(at: imageIndex)

        updateStepImagesDisplay(stepNumber: stepNumber)
        checkForChanges()
    }

    @objc func addStepTapped() {
        let stepNumber = stepsStackView.arrangedSubviews.count + 1
        let stepView = createStepView(stepNumber: stepNumber)
        stepsStackView.addArrangedSubview(stepView)
        checkForChanges()
    }

    func collectSteps() -> [RecipeStep] {
        var steps: [RecipeStep] = []

        for (index, view) in stepsStackView.arrangedSubviews.enumerated() {
            let stepNumber = index + 1

            guard let stepTextField = view.viewWithTag(1000 + stepNumber) as? UITextField,
                  let text = stepTextField.text?.trimmingCharacters(in: .whitespaces),
                  !text.isEmpty else {
                continue
            }

            var recipeImages: [RecipeImage] = []
            if let images = stepImages[stepNumber] {
                for (imageIndex, image) in images.enumerated() {
                    if let savedPath = saveImageToLocal(image: image, stepNumber: stepNumber, imageIndex: imageIndex) {
                        let recipeImage = RecipeImage(
                            source: .localPath,
                            value: savedPath,
                            isThumbnail: false
                        )
                        recipeImages.append(recipeImage)
                    }
                }
            }

            let step = RecipeStep(
                index: stepNumber,
                text: text,
                images: recipeImages
            )
            steps.append(step)
        }

        return steps
    }

    func loadSteps(_ steps: [RecipeStep]) {
        stepsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !steps.isEmpty else {
            addInitialStep()
            return
        }

        for (index, step) in steps.enumerated() {
            let stepNumber = index + 1
            let stepView = createStepView(stepNumber: stepNumber)
            stepsStackView.addArrangedSubview(stepView)

            if let stepTextField = stepView.viewWithTag(1000 + stepNumber) as? UITextField {
                stepTextField.text = step.text
            }

            var images: [UIImage] = []
            for recipeImage in step.images {
                if let image = UIImage(contentsOfFile: recipeImage.value) {
                    images.append(image)
                }
            }

            if !images.isEmpty {
                stepImages[stepNumber] = images
                updateStepImagesDisplay(stepNumber: stepNumber)
            }
        }
    }
}
