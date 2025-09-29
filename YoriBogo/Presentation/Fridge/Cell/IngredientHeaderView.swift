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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
        }
    }
    
}
