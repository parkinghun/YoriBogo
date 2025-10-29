//
//  EmptyStateView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import UIKit
import SnapKit

final class EmptyStateView: BaseView, ConfigureView {

    // MARK: - Configuration
    struct Configuration {
        let image: UIImage?
        let title: String
        let subtitle: String
        let buttonTitle: String?

        init(
            image: UIImage? = nil,
            title: String,
            subtitle: String,
            buttonTitle: String? = nil
        ) {
            self.image = image
            self.title = title
            self.subtitle = subtitle
            self.buttonTitle = buttonTitle
        }
    }

    // MARK: - UI Components
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .gray500
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.pageTitle
        label.textColor = .gray800
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body
        label.textColor = .gray600
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private(set) var ctaButton: RoundedButton?

    private lazy var textStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierachy()
    }

    // MARK: - Configuration
    func configure(with config: Configuration) {
        // 이미지 설정
        if let image = config.image {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }

        // 텍스트 설정
        titleLabel.text = config.title
        subtitleLabel.text = config.subtitle

        // 버튼 설정
        if let buttonTitle = config.buttonTitle {
            if ctaButton == nil {
                let button = RoundedButton(
                    title: buttonTitle,
                    titleColor: .white,
                    backgroundColor: .brandOrange600
                )
                ctaButton = button
                addSubview(button)
            } else {
                ctaButton?.setTitle(buttonTitle, for: .normal)
            }
            ctaButton?.isHidden = false
        } else {
            ctaButton?.isHidden = true
        }

        // 레이아웃 업데이트
        configureLayout()
    }

    func configureHierachy() {
        addSubview(imageView)
        addSubview(textStackView)
    }

    func configureLayout() {
        // 이미지가 있는 경우와 없는 경우 레이아웃 다르게
        if !imageView.isHidden {
            imageView.snp.remakeConstraints { make in
                make.bottom.equalTo(textStackView.snp.top).offset(-16)
                make.centerX.equalToSuperview()
                make.size.equalTo(60)
            }
        }

        textStackView.snp.remakeConstraints { make in
            if imageView.isHidden {
                make.center.equalToSuperview()
            } else {
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-20)
            }
            make.horizontalEdges.equalToSuperview().inset(30)
        }

        // 버튼이 있는 경우
        if let button = ctaButton, !button.isHidden {
            button.snp.remakeConstraints { make in
                make.top.equalTo(textStackView.snp.bottom).offset(30)
                make.height.equalTo(44)
                make.horizontalEdges.equalToSuperview().inset(30)
            }
        }
    }
}
