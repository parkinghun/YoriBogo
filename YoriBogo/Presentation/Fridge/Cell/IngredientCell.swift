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
        label.font = AppFont.body
        label.textAlignment = .center
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
    
    private let outerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
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
    }
    
    func configure(image: UIImage?, title: String) {
        imageView.image = image
        titleLabel.text = title
    }
    
    func configureHierachy() {
        contentView.addSubview(outerView)
        outerView.addSubview(stackView)
    }
    
    func configureLayout() {
        stackView.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        outerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        imageView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(imageView.snp.width)
        }
    }
    
    //    private func updateUI(selected: Bool) {
    //        let color = isSelected ? UIColor.brandOrange400 : UIColor.gray500
    //
    //        iconView.tintColor = color
    //        titleLabel.textColor = color
    //        hilightBar.backgroundColor = isSelected ? UIColor.brandOrange400 : .white
    //        contentView.backgroundColor = isSelected ? UIColor.brandOrange100 : .white
    //    }
}

