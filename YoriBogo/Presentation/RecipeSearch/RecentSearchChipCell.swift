//
//  RecentSearchChipCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 11/2/25.
//

import UIKit
import SnapKit

final class RecentSearchChipCell: UICollectionViewCell, ReusableView {

    // MARK: - Properties
    var onDeleteTapped: ((String) -> Void)?
    private var keyword: String?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray100
        view.layer.cornerRadius = 16  // 높이 32 고정이므로 16으로 하드코딩
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.gray200.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let keywordLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body
        label.textColor = .darkGray
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .systemGray
        button.contentMode = .scaleAspectFit
        return button
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func deleteButtonTapped() {
        guard let keyword = keyword else { return }
        onDeleteTapped?(keyword)
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        [keywordLabel, deleteButton].forEach {
            containerView.addSubview($0)
        }

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(32)
        }

        keywordLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(6)
        }

        deleteButton.snp.makeConstraints {
            $0.leading.equalTo(keywordLabel.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        // label의 너비에 맞게 셀 크기 조정
        keywordLabel.setContentHuggingPriority(.required, for: .horizontal)
        keywordLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Configuration
    func configure(with keyword: String) {
        self.keyword = keyword
        keywordLabel.text = keyword
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 32)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        return layoutAttributes
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        keyword = nil
        keywordLabel.text = nil
        onDeleteTapped = nil
    }
}
