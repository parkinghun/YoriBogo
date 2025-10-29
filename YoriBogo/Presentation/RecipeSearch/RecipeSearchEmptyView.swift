//
//  RecipeSearchEmptyView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import SnapKit

final class RecipeSearchEmptyView: BaseView, ConfigureView {
    private let emptyStateView = EmptyStateView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
        configureLayout()
    }

    func configure(state: State) {
        let config: EmptyStateView.Configuration

        switch state {
        case .initial:
            config = EmptyStateView.Configuration(
                image: UIImage(systemName: "magnifyingglass"),
                title: "레시피를 검색해보세요",
                subtitle: "레시피 이름, 냉장고 속 재료로 검색할 수 있어요",
                buttonTitle: nil
            )
        case .noResult:
            config = EmptyStateView.Configuration(
                image: UIImage(systemName: "magnifyingglass"),
                title: "검색 결과가 없어요",
                subtitle: "다른 키워드로 다시 시도해보세요",
                buttonTitle: nil
            )
        }

        emptyStateView.configure(with: config)
    }

    func configureHierachy() {
        addSubview(emptyStateView)
    }

    func configureLayout() {
        emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension RecipeSearchEmptyView {
    enum State {
        case initial
        case noResult
    }
}
