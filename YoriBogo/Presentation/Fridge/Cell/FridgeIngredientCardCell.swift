//
//  FridgeIngredientCardCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import UIKit
import SnapKit

final class FridgeIngredientCardCell: UICollectionViewCell, ReusableView {
    private let containerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false
        return view
    }()

    private let imageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .gray100
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        return iv
    }()

    private let nameLabel = {
        let label = UILabel()
        label.font = Pretendard.semiBold.of(size: 16)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let quantityLabel = {
        let label = UILabel()
        label.font = Pretendard.regular.of(size: 14)
        label.textColor = .gray600
        label.textAlignment = .center
        return label
    }()

    private let dDayBadge = {
        let label = PaddingLabel(padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        label.font = Pretendard.semiBold.of(size: 12)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
        quantityLabel.text = nil
        dDayBadge.text = nil
        dDayBadge.isHidden = true
    }

    func configure(with item: FridgeIngredientDetail) {
        imageView.image = UIImage(named: item.imageKey)
        nameLabel.text = item.name

        if let qty = item.qty, let unit = item.unit {
            quantityLabel.text = "\(Int(qty))\(unit)"
        } else if let qty = item.qty {
            quantityLabel.text = "\(Int(qty))개"
        } else {
            quantityLabel.text = "수량 미정"
        }

        // D-Day 배지 설정
        if let expirationDate = item.expirationDate {
            configureDDayBadge(for: expirationDate)
        } else {
            dDayBadge.isHidden = true
        }
    }

    private func configureDDayBadge(for date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiration = calendar.startOfDay(for: date)

        let components = calendar.dateComponents([.day], from: today, to: expiration)
        guard let daysLeft = components.day else {
            dDayBadge.isHidden = true
            return
        }

        dDayBadge.isHidden = false

        switch daysLeft {
        case ..<0:
            dDayBadge.text = "만료"
            dDayBadge.backgroundColor = .gray400
            dDayBadge.textColor = .white
        case 0:
            dDayBadge.text = "D-Day"
            dDayBadge.backgroundColor = .systemRed
            dDayBadge.textColor = .white
        case 1...3:
            dDayBadge.text = "D-\(daysLeft)"
            dDayBadge.backgroundColor = .systemRed
            dDayBadge.textColor = .white
        case 4...7:
            dDayBadge.text = "D-\(daysLeft)"
            dDayBadge.backgroundColor = .systemOrange
            dDayBadge.textColor = .white
        default:
            dDayBadge.text = "D-\(daysLeft)"
            dDayBadge.backgroundColor = .gray200
            dDayBadge.textColor = .gray700
        }
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(dDayBadge)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(imageView.snp.width).multipliedBy(0.8)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(12)
        }

        quantityLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.horizontalEdges.equalToSuperview().inset(12)
        }

        dDayBadge.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.trailing.equalToSuperview().inset(8)
        }
    }
}

// MARK: - PaddingLabel Helper
class PaddingLabel: UILabel {
    private var padding: UIEdgeInsets

    init(padding: UIEdgeInsets) {
        self.padding = padding
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += padding.left + padding.right
        size.height += padding.top + padding.bottom
        return size
    }
}
