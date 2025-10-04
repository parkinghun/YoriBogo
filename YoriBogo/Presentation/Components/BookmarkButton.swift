//
//  BookmarkButton.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit

final class BookmarkButton: UIButton {

    // MARK: - Initialization
    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        setImage(UIImage(systemName: "heart"), for: .normal)
        setImage(UIImage(systemName: "heart.fill"), for: .selected)
        tintColor = .systemOrange
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
    }

    // MARK: - Public Methods
    func setBookmarked(_ isBookmarked: Bool) {
        isSelected = isBookmarked
    }
}
