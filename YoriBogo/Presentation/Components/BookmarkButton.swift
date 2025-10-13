//
//  BookmarkButton.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit

final class BookmarkButton: UIButton {

    // MARK: - Initialization
    convenience init(radius: CGFloat = 24) {
        self.init()
        self.layer.cornerRadius = radius
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        setImage(UIImage(systemName: "heart"), for: .normal)
        setImage(UIImage(systemName: "heart.fill"), for: .selected)
        tintColor = .brandOrange500
        backgroundColor = .white
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        isUserInteractionEnabled = true
    }

    // MARK: - Public Methods
    func setBookmarked(_ isBookmarked: Bool) {
        isSelected = isBookmarked
    }
}
