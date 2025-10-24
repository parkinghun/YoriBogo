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
        stepTextField.addTarget(self, action: #selector(stepTextFieldDidChange), for: .editingChanged)

        let imageScrollView = UIScrollView()
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.tag = 2000 + stepNumber

        let imageStackView = UIStackView()
        imageStackView.axis = .horizontal
        imageStackView.spacing = 8
        imageStackView.alignment = .leading
        imageStackView.distribution = .fill
        imageStackView.tag = 3000 + stepNumber

        // 이미지 추가 버튼을 셀 형태로 생성
        let addImageButton = UIButton()
        addImageButton.backgroundColor = .gray100
        addImageButton.layer.cornerRadius = 8
        addImageButton.tag = stepNumber
        addImageButton.addTarget(self, action: #selector(addImageButtonTapped(_:)), for: .touchUpInside)

        // 갤러리 아이콘
        let galleryIcon = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
        galleryIcon.tintColor = .gray400
        galleryIcon.contentMode = .scaleAspectFit

        // 카운터 레이블
        let counterLabel = UILabel()
        counterLabel.text = "(0/5)"
        counterLabel.font = .systemFont(ofSize: 12, weight: .medium)
        counterLabel.textColor = .gray500
        counterLabel.textAlignment = .center
        counterLabel.tag = 4000 + stepNumber // 카운터 레이블 태그

        addImageButton.addSubview(galleryIcon)
        addImageButton.addSubview(counterLabel)

        galleryIcon.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
            $0.size.equalTo(32)
        }

        counterLabel.snp.makeConstraints {
            $0.top.equalTo(galleryIcon.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
        }

        imageScrollView.addSubview(imageStackView)
        imageStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        // 버튼을 스택뷰의 첫 번째로 추가
        imageStackView.addArrangedSubview(addImageButton)
        addImageButton.snp.makeConstraints {
            $0.width.height.equalTo(100)
        }

        containerView.addSubview(numberLabel)
        containerView.addSubview(stepTextField)
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

        imageScrollView.snp.makeConstraints {
            $0.top.equalTo(stepTextField.snp.bottom).offset(16)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(100)
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
        // ViewModel에게 이미지 추가 알림
        stepImagesAddedRelay.accept((stepNumber: stepNumber, images: images))
    }

    func updateStepImagesDisplay(stepNumber: Int) {
        guard let stackView = view.viewWithTag(3000 + stepNumber) as? UIStackView else { return }

        let imagePaths = stepImagePaths[stepNumber] ?? []
        let imageCount = imagePaths.count

        // 카운터 레이블 업데이트
        if let counterLabel = view.viewWithTag(4000 + stepNumber) as? UILabel {
            counterLabel.text = "(\(imageCount)/5)"
        }

        // 첫 번째 버튼 가져오기 (이미 생성되어 있음)
        let addButton = stackView.arrangedSubviews.first

        // 버튼을 제외한 나머지 이미지들 제거
        stackView.arrangedSubviews.dropFirst().forEach { $0.removeFromSuperview() }

        // 이미지 5개일 때 버튼 숨기기
        addButton?.isHidden = (imageCount >= 5)

        // 이미지들 추가
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
    }

    @objc func deleteImageButtonTapped(_ sender: UIButton) {
        guard let container = sender.superview,
              let stackView = container.superview as? UIStackView else { return }

        let stepNumber = container.tag / 10000
        let imageIndex = sender.tag

        // ViewModel에게 이미지 삭제 알림
        stepImageRemovedRelay.accept((stepNumber: stepNumber, index: imageIndex))
    }

    @objc func addStepTapped() {
        let stepNumber = stepsStackView.arrangedSubviews.count + 1
        let stepView = createStepView(stepNumber: stepNumber)
        stepsStackView.addArrangedSubview(stepView)
        // 단계 추가 이벤트를 NotificationCenter로 알림
        NotificationCenter.default.post(name: Notification.Name("StepChanged"), object: nil)
    }

    @objc func stepTextFieldDidChange() {
        // 단계 변경 이벤트를 NotificationCenter로 알림
        NotificationCenter.default.post(name: Notification.Name("StepChanged"), object: nil)
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

            // 이미지 저장은 ViewModel에서 처리하므로, 여기서는 텍스트만 수집
            let step = RecipeStep(
                index: stepNumber,
                text: text,
                images: [] // 빈 배열로 전달, ViewModel에서 이미지를 추가함
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
        }

        // Note: 이미지 로딩은 ViewModel에서 처리하고,
        // stepImagePaths output 바인딩을 통해 UI가 업데이트됩니다.
    }
}
