//
//  IngredientHeaderView.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/30/25.
//

import UIKit
import SnapKit

final class IngredientHeaderView: UICollectionReusableView, ReusableView {

    private let titleLabel = {
        let label = UILabel()
        label.font = AppFont.sectionTitle
        label.textColor = UIColor.black
        return label
    }()

    private let countBadge = {
        let label = UILabel()
        label.font = Pretendard.medium.of(size: 14)
        label.textColor = .brandOrange600
        label.backgroundColor = .brandOrange100
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var stackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, countBadge])
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countBadge.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, count: Int? = nil) {
        titleLabel.text = title
        guard let count else {
            countBadge.isHidden = true
            return
        }
        countBadge.isHidden = false
        countBadge.text = "\(count)개"
    }

    private func setupUI() {
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.leading.equalToSuperview()  // 4
            $0.centerY.equalToSuperview()
        }

        countBadge.snp.makeConstraints {
            $0.height.equalTo(24)
            $0.width.greaterThanOrEqualTo(40)
        }
    }
}
