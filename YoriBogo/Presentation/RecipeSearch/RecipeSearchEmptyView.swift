//
//  RecipeSearchEmptyView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import SnapKit

final class RecipeSearchEmptyView: BaseView, ConfigureView {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "magnifyingglass")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .gray500
        return iv
    }()
    
    let titleLabel = {
        let label = UILabel()
        label.font = AppFont.pageTitle
        return label
    }()
    
    let subTitleLabel = {
        let label = UILabel()
        label.font = AppFont.body
        label.textColor = .gray600
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
        configureLayout()
    }
    
    func configure(state: State) {
        switch state {
        case .initial:
            titleLabel.text = "레시피를 검색해보세요"
            subTitleLabel.text = "레시피 이름, 냉장고 속 재료로 검색할 수 있어요"
        case .noResult:
            titleLabel.text = "검색 결과가 없어요"
            subTitleLabel.text = "다른 키워드로 다시 시도해보세요"
        }
    }
    
    func configureHierachy() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
    }
    
    func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp.top).offset(-4)
            make.centerX.equalToSuperview()
            make.size.equalTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
    }
    
}

extension RecipeSearchEmptyView {
    enum State {
        case initial
        case noResult
    }
}
