//
//  IngredientCategoryCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import SnapKit

final class IngredientCategoryCell: UICollectionViewCell, ReusableView, ConfigureView {
    private let iconView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let titleLabel = {
       let label = UILabel()
        label.font = AppFont.button
        label.textAlignment = .center
        return label
    }()
    
    private lazy var stackView = {
        let sv = UIStackView(arrangedSubviews: [iconView, titleLabel])
        sv.axis = .vertical
        sv.spacing = Spacing.small
        sv.alignment = .center
        sv.distribution = .fill
        return sv
    }()
    
    private let hilightBar = UIView()
    
    override var isSelected: Bool {
        didSet {
            updateUI(selected: isSelected)
        }
    }
       
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        iconView.image = nil
        titleLabel.text = nil
        hilightBar.backgroundColor = .white
    }
    
    func configure(icon: UIImage?, title: String, selected: Bool) {
        iconView.image = icon
        titleLabel.text = title
        self.isSelected = selected
    }
    
    func configureHierachy() {
        contentView.addSubview(stackView)
        contentView.addSubview(hilightBar)
    }
    
    func configureLayout() {
        stackView.snp.makeConstraints { $0.center.equalToSuperview() }
        hilightBar.snp.makeConstraints {
            $0.verticalEdges.trailing.equalToSuperview()
            $0.width.equalTo(2)
            $0.height.equalToSuperview()
        }
    }
    
    private func updateUI(selected: Bool) {
        let color = isSelected ? UIColor.brandOrange400 : UIColor.gray500
        
        iconView.tintColor = color
        titleLabel.textColor = color
        hilightBar.backgroundColor = isSelected ? UIColor.brandOrange400 : .white
        contentView.backgroundColor = isSelected ? UIColor.brandOrange100 : .white
    }
}
