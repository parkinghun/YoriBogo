//
//  IngredientCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/30/25.
//

import UIKit
import SnapKit

final class IngredientCell: UICollectionViewCell, ReusableView, ConfigureView {
    private let imageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor.gray100
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        return iv
    }()
    
    private let titleLabel = {
        let label = UILabel()
        label.font = AppFont.button
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var stackView = {
        let sv = UIStackView(arrangedSubviews: [imageView, titleLabel])
        sv.axis = .vertical
        sv.spacing = Spacing.small
        sv.alignment = .center
        sv.distribution = .fill
        return sv
    }()
    
    private let checkmarkContainer = {
        let view = UIView()
        view.backgroundColor = .brandOrange600
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    private let checkmarkIcon = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let outerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        titleLabel.text = nil
        updateUI(selected: false)
    }
    
    func configure(image: UIImage?, title: String, isSelected: Bool) {
        imageView.image = image
        titleLabel.text = title
        updateUI(selected: isSelected)
    }
    
    
    private func updateUI(selected: Bool) {
        if selected {
            outerView.backgroundColor = .brandOrange200
            outerView.layer.borderColor = UIColor.brandOrange400.cgColor
            checkmarkContainer.isHidden = false
        } else {
            outerView.backgroundColor = .white
            outerView.layer.borderColor = UIColor.gray100.cgColor
            checkmarkContainer.isHidden = true
        }
    }
    
    func configureHierachy() {
        contentView.addSubview(outerView)
        outerView.addSubview(stackView)
        outerView.addSubview(checkmarkContainer)
        checkmarkContainer.addSubview(checkmarkIcon)
    }
    
    func configureLayout() {
        outerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        stackView.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        
        imageView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(imageView.snp.width)
        }
        
        checkmarkContainer.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.top).offset(-4)
            $0.trailing.equalTo(imageView.snp.trailing).offset(4)
            $0.width.height.equalTo(24)
        }
        
        checkmarkIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(14)
        }
    }
}

