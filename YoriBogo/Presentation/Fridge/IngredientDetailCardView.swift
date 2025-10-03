//
//  IngredientDetailCardView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/3/25.
//

import UIKit
import SnapKit

final class IngredientDetailCardView: UIView {

    private let dimmedBackgroundView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()

    private let cardContainerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()

    private let headerView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let nameLabel = {
        let label = UILabel()
        label.font = Pretendard.bold.of(size: 20)
        label.textColor = .black
        return label
    }()

    private let editButton = {
        let button = UIButton()
        button.setTitle("수정하기", for: .normal)
        button.setTitleColor(.brandOrange600, for: .normal)
        button.titleLabel?.font = Pretendard.medium.of(size: 14)
        return button
    }()

    let closeButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .gray600
        return button
    }()

    // MARK: - Content
    private let ingredientImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .gray100
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        return iv
    }()

    // MARK: - Info Rows
    private let infoStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()

    private let categoryRow = InfoRowView(title: "카테고리")
    private let quantityRow = InfoRowView(title: "수량")
    private let expirationRow = InfoRowView(title: "소비기한")

    // MARK: - Action Buttons
    private let buttonStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        return sv
    }()

    let consumeButton = {
        let button = UIButton()
        button.backgroundColor = .statusGreen500
        button.setTitle("소진", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Pretendard.semiBold.of(size: 16)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        return button
    }()

    let discardButton = {
        let button = UIButton()
        button.backgroundColor = .statusRed500
        button.setTitle("폐기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Pretendard.semiBold.of(size: 16)
        button.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)  // titlePadding
        return button
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        addSubview(dimmedBackgroundView)
        addSubview(cardContainerView)

        cardContainerView.addSubview(headerView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(editButton)
        headerView.addSubview(closeButton)

        cardContainerView.addSubview(ingredientImageView)
        cardContainerView.addSubview(infoStackView)
        infoStackView.addArrangedSubview(categoryRow)
        infoStackView.addArrangedSubview(quantityRow)
        infoStackView.addArrangedSubview(expirationRow)

        cardContainerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(consumeButton)
        buttonStackView.addArrangedSubview(discardButton)

        setupConstraints()
    }

    private func setupConstraints() {
        dimmedBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        cardContainerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(30)
        }

        // Header
        headerView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(60)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        editButton.snp.makeConstraints {
            $0.leading.equalTo(nameLabel.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        // Content
        ingredientImageView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(120)
        }

        infoStackView.snp.makeConstraints {
            $0.top.equalTo(ingredientImageView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        // Buttons
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(infoStackView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
            $0.height.equalTo(56)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimmedViewTapped))
        dimmedBackgroundView.addGestureRecognizer(tapGesture)
    }

    @objc private func dimmedViewTapped() {
        dismiss()
    }

    // MARK: - Public Methods
    func configure(with detail: FridgeIngredientDetail) {
        nameLabel.text = detail.name
        ingredientImageView.image = UIImage(named: detail.imageKey)

        // 카테고리
        categoryRow.setValue(detail.categoryName)

        // 수량 정보
        if let qty = detail.qty, let unit = detail.unit {
            quantityRow.setValue("\(Int(qty))\(unit)")
        } else if let qty = detail.qty {
            quantityRow.setValue("\(Int(qty))개")
        } else {
            quantityRow.setValue("수량 미정")
        }

        // 소비기한 정보
        if let expirationDate = detail.expirationDate {
            let (dateString, dDay, color) = formatExpirationDate(expirationDate)
            expirationRow.setValue("\(dateString) (\(dDay))", color: color)
        } else {
            expirationRow.setValue("미정")
        }
    }

    func show(in view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 애니메이션
        self.alpha = 0
        cardContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.cardContainerView.transform = .identity
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.cardContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Private
    private func formatExpirationDate(_ date: Date) -> (dateString: String, dDay: String, color: UIColor) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiration = calendar.startOfDay(for: date)

        let components = calendar.dateComponents([.day], from: today, to: expiration)
        guard let daysLeft = components.day else { return ("", "", .black) }

        // D-Day 계산
        let dDay: String
        if daysLeft < 0 {
            dDay = "만료"
        } else if daysLeft == 0 {
            dDay = "D-Day"
        } else {
            dDay = "D-\(daysLeft)"
        }

        // 색상 결정
        let color: UIColor
        if daysLeft < 0 {
            color = .gray400
        } else if daysLeft <= 3 {
            color = .systemRed
        } else if daysLeft <= 7 {
            color = .systemOrange
        } else {
            color = .black
        }

        // 날짜 포맷 (같은 연도인지 확인)
        let isSameYear = calendar.component(.year, from: today) == calendar.component(.year, from: expiration)
        let dateString = isSameYear
            ? DateFormatter.expirationDetailSameYear.string(from: date)
            : DateFormatter.expirationDetailDifferentYear.string(from: date)

        return (dateString, dDay, color)
    }
}

// MARK: - InfoRowView
private final class InfoRowView: UIView {
    private let titleLabel = {
        let label = UILabel()
        label.font = Pretendard.medium.of(size: 16)
        label.textColor = .gray700
        return label
    }()

    private let valueLabel = {
        let label = UILabel()
        label.font = Pretendard.semiBold.of(size: 16)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
        }

        snp.makeConstraints {
            $0.height.equalTo(24)
        }
    }

    func setValue(_ value: String, color: UIColor = .black) {
        valueLabel.text = value
        valueLabel.textColor = color
    }
}
