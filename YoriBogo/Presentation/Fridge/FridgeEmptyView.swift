//
//  FridgeEmptyView.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import SnapKit

final class FridgeEmptyView: BaseView, ConfigureView {
    
    //    private let imageView: UIImageView = {
    //           let iv = UIImageView()
    //           iv.image = UIImage(named: "empty_fridge")
    //           iv.contentMode = .scaleAspectFit
    //           return iv
    //       }()
    //
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "앗! 냉장고가 텅텅 비었어요"
        label.font = AppFont.pageTitle
        label.textColor = UIColor.gray800
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "맛있는 요리를 위해\n냉장고를 채워보세요"
        label.font = AppFont.caption
        label.textColor = UIColor.gray600
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    let ctaButton = RoundedButton(title: "냉장고 채우러 가기", titleColor: .white, backgroundColor: UIColor.brandOrange600)
    
    lazy var stackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
        configureLayout()
    }
    
    
    func configureHierachy() {
        addSubview(stackView)
        addSubview(ctaButton)
    }
    
    func configureLayout() {
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        ctaButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(30)
            make.height.equalTo(44)
            make.horizontalEdges.equalToSuperview().inset(30)
        }
    }
}
