//
//  RecommendMainHeaderView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/5/25.
//

import UIKit
import SnapKit

final class RecommendMainHeaderView: UICollectionReusableView {

    static let id = "RecommendMainHeaderView"

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "지금 냉장고에 딱 맞는 레시피"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .darkGray
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "보유 재료로 만들 수 있는 추천 요리 TOP 5"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray
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
        [titleLabel, subtitleLabel].forEach {
            addSubview($0)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    // MARK: - Configuration
    func configure(subtitle: String) {
        subtitleLabel.text = subtitle
    }
}
