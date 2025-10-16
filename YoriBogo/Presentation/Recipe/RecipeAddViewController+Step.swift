//
//  RecipeAddViewController+Step.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-15.
//

import UIKit
import SnapKit
import Kingfisher

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
        stepTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

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

        let currentImageCount = stepImagePaths[stepNumber]?.count ?? 0
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
        // 이미지를 임시 캐시에 저장하고 경로만 보관
        let tempPaths = images.map { ImageCacheHelper.shared.cacheTempImage($0) }

        var currentPaths = stepImagePaths[stepNumber] ?? []
        currentPaths.append(contentsOf: tempPaths)
        stepImagePaths[stepNumber] = currentPaths

        updateStepImagesDisplay(stepNumber: stepNumber)
        checkForChanges()
    }

    func updateStepImagesDisplay(stepNumber: Int) {
        guard let imagePaths = stepImagePaths[stepNumber],
              !imagePaths.isEmpty else {
            if let scrollView = view.viewWithTag(2000 + stepNumber) {
                scrollView.snp.updateConstraints {
                    $0.height.equalTo(0)
                }
            }
            return
        }

        guard let stackView = view.viewWithTag(3000 + stepNumber) as? UIStackView else { return }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, imagePath) in imagePaths.enumerated() {
            let imageContainer = UIView()

            let imageView = UIImageView()
            // 경로에서 이미지 로드 (임시 캐시 또는 파일 시스템)
            imageView.image = ImageCacheHelper.shared.loadImage(at: imagePath)
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

        // 임시 캐시에서 이미지 삭제
        if let pathToRemove = stepImagePaths[stepNumber]?[imageIndex],
           ImageCacheHelper.shared.isTempPath(pathToRemove) {
            ImageCacheHelper.shared.removeTempImage(at: pathToRemove)
        }

        stepImagePaths[stepNumber]?.remove(at: imageIndex)

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
            if let imagePaths = stepImagePaths[stepNumber] {
                // API 레시피로부터 만들기인 경우, 모든 이미지를 새로 저장
                if isCreateFromApi {
                    for (imageIndex, imagePath) in imagePaths.enumerated() {
                        // 경로에서 이미지 로드 (임시 캐시 또는 파일)
                        guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                            continue
                        }

                        if let savedPath = saveImageToLocal(image: image, stepNumber: stepNumber, imageIndex: imageIndex) {
                            let recipeImage = RecipeImage(
                                source: .localPath,
                                value: savedPath,
                                isThumbnail: false
                            )
                            recipeImages.append(recipeImage)
                        }
                    }
                } else {
                    // 일반 편집 모드: 기존 이미지는 재사용, 새 이미지만 저장
                    let originalPaths = originalStepImagePaths[stepNumber] ?? []

                    for (imageIndex, imagePath) in imagePaths.enumerated() {
                        // 기존 이미지인지 확인 (originalStepImagePaths와 같은 인덱스에 있으면 기존 이미지)
                        if imageIndex < originalPaths.count {
                            // 기존 이미지 경로 재사용
                            let recipeImage = RecipeImage(
                                source: .localPath,
                                value: originalPaths[imageIndex],
                                isThumbnail: false
                            )
                            recipeImages.append(recipeImage)
                        } else {
                            // 새로운 이미지 저장 (임시 캐시에서 로드)
                            guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                                continue
                            }

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

                    // 삭제된 이미지 처리 (originalPaths보다 imagePaths가 적으면)
                    if imagePaths.count < originalPaths.count {
                        for index in imagePaths.count..<originalPaths.count {
                            deleteImageFile(at: originalPaths[index])
                        }
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

            guard !step.images.isEmpty else { continue }

            // 각 단계마다 독립적인 DispatchGroup 생성
            let group = DispatchGroup()
            var loadedImages: [(index: Int, image: UIImage)] = []
            var imagePaths: [String] = []

            for (imageIndex, recipeImage) in step.images.enumerated() {
                imagePaths.append(recipeImage.value)
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
                            loadedImages.append((imageIndex, imageResult.image))
                        case .failure(let error):
                            print("❌ Step \(stepNumber) 이미지 다운로드 실패: \(error)")
                        }
                        group.leave()
                    }

                case .localPath:
                    // 로컬 파일에서 이미지 로드 (파일 존재 확인 포함)
                    if let image = ImagePathHelper.shared.loadImage(at: recipeImage.value) {
                        loadedImages.append((imageIndex, image))
                    } else {
                        print("⚠️ Step \(stepNumber) 이미지 파일을 찾을 수 없음: \(recipeImage.value)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }

                // 인덱스 순서대로 정렬
                loadedImages.sort { $0.index < $1.index }

                // 이미지를 임시 캐시에 저장하고 경로 반환
                let tempPaths = loadedImages.map { _, image in
                    ImageCacheHelper.shared.cacheTempImage(image)
                }

                if !tempPaths.isEmpty {
                    self.stepImagePaths[stepNumber] = tempPaths
                    self.originalStepImagePaths[stepNumber] = imagePaths
                    self.updateStepImagesDisplay(stepNumber: stepNumber)
                }
            }
        }
    }
}
