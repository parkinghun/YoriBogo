//
//  RecommendSectionHeaderView.swift
//  YoriBogo
//
//  Created by Claude on 10/5/25.
//

import UIKit
import SnapKit

final class RecommendSectionHeaderView: UICollectionReusableView {

    static let id = "RecommendSectionHeaderView"

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .darkGray
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
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(title: String) {
        titleLabel.text = title
    }
}
