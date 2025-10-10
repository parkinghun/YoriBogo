//
//  FridgeCategoryChipCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import UIKit
import SnapKit

final class FridgeCategoryChipCell: UICollectionViewCell, ReusableView {

    private let titleLabel = {
        let label = UILabel()
        label.font = Pretendard.medium.of(size: 14)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        updateUI(isSelected: false)
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        updateUI(isSelected: isSelected)
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

        contentView.addSubview(titleLabel)
        
        contentView.snp.makeConstraints { $0.height.equalTo(40) }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }

    private func updateUI(isSelected: Bool) {
        if isSelected {
            contentView.backgroundColor = .brandOrange500
            titleLabel.textColor = .white
        } else {
            contentView.backgroundColor = .gray100
            titleLabel.textColor = .black
        }
    }
}
