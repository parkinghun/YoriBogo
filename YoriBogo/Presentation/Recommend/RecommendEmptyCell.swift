//
//  RecommendEmptyCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/5/25.
//

import UIKit
import SnapKit

final class RecommendEmptyCell: UICollectionViewCell, ReusableView {

    // MARK: - UI Components
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "북마크한 레시피가 없습니다"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
