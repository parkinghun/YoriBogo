//
//  ActionButton.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-16.
//

import UIKit

final class ActionButton: UIButton {

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(
        title: String,
        titleColor: UIColor = .white,
        backgroundColor: UIColor,
        image: UIImage? = nil,
        imageTintColor: UIColor = .white,
        font: UIFont = Pretendard.semiBold.of(size: 16),
        cornerRadius: CGFloat = 12
    ) {
        self.init(frame: .zero)
        setupButton(
            title: title,
            titleColor: titleColor,
            backgroundColor: backgroundColor,
            image: image,
            imageTintColor: imageTintColor,
            font: font,
            cornerRadius: cornerRadius
        )
    }

    // MARK: - Setup
    private func setupButton(
        title: String,
        titleColor: UIColor,
        backgroundColor: UIColor,
        image: UIImage?,
        imageTintColor: UIColor,
        font: UIFont,
        cornerRadius: CGFloat
    ) {
        self.backgroundColor = backgroundColor
        setTitle(title, for: .normal)
        setTitleColor(titleColor, for: .normal)
        titleLabel?.font = font

        if let image = image {
            setImage(image, for: .normal)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        }

        tintColor = imageTintColor
        layer.cornerRadius = cornerRadius
    }

    // MARK: - Public Methods
    func updateTitle(_ title: String) {
        setTitle(title, for: .normal)
    }

    func updateImage(_ image: UIImage?) {
        setImage(image, for: .normal)
        if image != nil {
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        }
    }

    func updateBackgroundColor(_ color: UIColor) {
        backgroundColor = color
    }
}
