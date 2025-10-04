//
//  BadgeLabel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit

final class BadgeLabel: UILabel {

    // MARK: - Initialization
    init(text: String = "", backgroundColor: UIColor = .systemOrange) {
        super.init(frame: .zero)
        setupUI(text: text, backgroundColor: backgroundColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI(text: String, backgroundColor: UIColor) {
        self.text = text
        self.font = .systemFont(ofSize: 14, weight: .semibold)
        self.textColor = .white
        self.backgroundColor = backgroundColor
        self.textAlignment = .center
        self.layer.cornerRadius = 18
        self.clipsToBounds = true
    }

    // MARK: - Public Methods
    func updateText(_ text: String) {
        self.text = text
        invalidateIntrinsicContentSize()
    }

    // MARK: - Override for padding
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 24, height: 36)
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        super.drawText(in: rect.inset(by: insets))
    }
}
