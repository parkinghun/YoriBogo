//
//  RecipeAddViewController+MainImage.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-15.
//

import UIKit

// MARK: - Main Image Management
extension RecipeAddViewController {

    @objc func addMainImageButtonTapped() {
        let currentImageCount = mainImages.count
        let remainingCount = 5 - currentImageCount

        guard remainingCount > 0 else {
            showAlert(message: "메인 이미지는 최대 5장까지 추가할 수 있습니다")
            return
        }

        imagePickerManager.presentImagePicker(
            from: self,
            maxSelectionCount: remainingCount
        ) { [weak self] images in
            self?.addMainImages(images)
        }
    }

    func addMainImages(_ images: [UIImage]) {
        mainImages.append(contentsOf: images)
        updateMainImageDisplay()
        checkForChanges()
    }

    func updateMainImageDisplay() {
        if mainImages.isEmpty {
            emptyMainImageView.isHidden = false
            mainImageScrollView.isHidden = true
            mainImagePageControl.isHidden = true
        } else {
            emptyMainImageView.isHidden = true
            mainImageScrollView.isHidden = false
            mainImagePageControl.isHidden = false

            mainImageScrollView.subviews.forEach { $0.removeFromSuperview() }

            let scrollViewWidth = UIScreen.main.bounds.width - 40
            let scrollViewHeight: CGFloat = 240

            mainImageScrollView.contentSize = CGSize(
                width: scrollViewWidth * CGFloat(mainImages.count),
                height: scrollViewHeight
            )

            for (index, image) in mainImages.enumerated() {
                let pageView = UIView(frame: CGRect(
                    x: scrollViewWidth * CGFloat(index),
                    y: 0,
                    width: scrollViewWidth,
                    height: scrollViewHeight
                ))

                let imageView = UIImageView()
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 16

                let deleteButton = UIButton()
                deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
                deleteButton.tintColor = .white
                deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                deleteButton.layer.cornerRadius = 16
                deleteButton.tag = index
                deleteButton.addTarget(self, action: #selector(deleteMainImageButtonTapped(_:)), for: .touchUpInside)

                pageView.addSubview(imageView)
                pageView.addSubview(deleteButton)

                imageView.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }

                deleteButton.snp.makeConstraints {
                    $0.top.trailing.equalToSuperview().inset(12)
                    $0.size.equalTo(32)
                }

                mainImageScrollView.addSubview(pageView)
            }

            mainImagePageControl.numberOfPages = mainImages.count
            mainImagePageControl.currentPage = 0
        }
    }

    @objc func deleteMainImageButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < mainImages.count else { return }

        mainImages.remove(at: index)
        updateMainImageDisplay()
        checkForChanges()
    }
}
