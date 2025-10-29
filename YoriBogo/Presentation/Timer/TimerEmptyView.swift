//
//  TimerEmptyView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import UIKit

final class TimerEmptyView: BaseView, ConfigureView {
    private let emptyStateView = EmptyStateView()

    var ctaButton: RoundedButton? {
        return emptyStateView.ctaButton
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
        configureLayout()
        configureContent()
    }

    func configureHierachy() {
        addSubview(emptyStateView)
    }

    func configureLayout() {
        emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureContent() {
        let config = EmptyStateView.Configuration(
            image: UIImage(systemName: "stopwatch"),
            title: "타이머가 없습니다",
            subtitle: "요리할 때 필요한 타이머를 추가해보세요",
            buttonTitle: "첫 번째 타이머 만들기"
        )
        emptyStateView.configure(with: config)
    }
}
