//
//  IngredientDetailInputCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import UIKit
import SnapKit

final class IngredientDetailInputCell: UICollectionViewCell, ReusableView {
    private let containerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let ingredientImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .gray100
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        return iv
    }()
    
    private let nameLabel = {
        let label = UILabel()
        label.font = Pretendard.semiBold.of(size: 18)
        label.textColor = .black
        return label
    }()
    
    private let categoryLabel = {
        let label = UILabel()
        label.font = Pretendard.regular.of(size: 14)
        label.textColor = .gray500
        return label
    }()
    
    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, categoryLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    
    private let quantityLabel = {
        let label = UILabel()
        label.text = "수량"
        label.font = Pretendard.medium.of(size: 14)
        label.textColor = .gray700
        return label
    }()
    
    private let quantityTextFieldView = BorderedTextFieldView(type: .quantity)
    private let unitTextFieldView = BorderedTextFieldView(type: .unit)

    private let expirationLabel = {
        let label = UILabel()
        label.text = "소비기한"
        label.font = Pretendard.medium.of(size: 14)
        label.textColor = .gray700
        return label
    }()

    private let dateTextField: DatePickerTextField = {
        let tf = DatePickerTextField(showClearButton: true)
        tf.placeholder = DateFormatter.expirationDate.string(from: .now)
        tf.font = AppFont.button
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 8
        tf.layer.borderColor = UIColor.gray200.cgColor
        tf.layer.borderWidth = 1
        tf.tintColor = .clear
        tf.dateFormatter = DateFormatter.expirationDate
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.tintColor = .gray600
        calendarIcon.frame = CGRect(x: 8, y: 10, width: 24, height: 24)
        rightPaddingView.addSubview(calendarIcon)
        tf.rightView = rightPaddingView
        tf.rightViewMode = .always
        return tf
    }()

    var onQuantityChanged: ((String) -> Void)?
    var onUnitChanged: ((String) -> Void)?
    var onDateSelected: ((Date?) -> Void)?

    private var currentIndex: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        quantityTextFieldView.textField.text = "1"
        unitTextFieldView.textField.text = nil
        dateTextField.text = nil
        onQuantityChanged = nil
        onUnitChanged = nil
        onDateSelected = nil
    }
    
    func configure(with detail: FridgeIngredientDetail, index: Int) {
        currentIndex = index
        
        ingredientImageView.image = UIImage(named: detail.imageKey)
        nameLabel.text = detail.name
        categoryLabel.text = detail.categoryName
        
        if let quantity = detail.qty {
            quantityTextFieldView.textField.text = String(format: "%.0f", quantity)
        } else {
            quantityTextFieldView.textField.text = nil
        }
        
        if let unit = detail.unit {
            unitTextFieldView.textField.text = unit
        } else {
            unitTextFieldView.textField.text = nil
        }

        dateTextField.setDate(detail.expirationDate)
    }
    
    private func configureHierarchy() {
        contentView.addSubview(containerView)
                
        containerView.addSubview(ingredientImageView)
        containerView.addSubview(infoStack)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(quantityTextFieldView)
        containerView.addSubview(unitTextFieldView)
        containerView.addSubview(expirationLabel)
        containerView.addSubview(dateTextField)
    }
    
    private func configureLayout() {
            containerView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            ingredientImageView.snp.makeConstraints {
                $0.top.leading.equalToSuperview().inset(16)
                $0.size.equalTo(48)
            }
            
            infoStack.snp.makeConstraints {
                $0.leading.equalTo(ingredientImageView.snp.trailing).offset(12)
                $0.trailing.equalToSuperview().inset(16)
                $0.centerY.equalTo(ingredientImageView)
            }
            
            quantityLabel.snp.makeConstraints {
                $0.top.equalTo(ingredientImageView.snp.bottom).offset(20)
                $0.leading.equalToSuperview().inset(16)
            }
            
            quantityTextFieldView.snp.makeConstraints {
                $0.top.equalTo(quantityLabel.snp.bottom).offset(8)
                $0.leading.equalToSuperview().inset(16)
                $0.height.equalTo(44)
            }
            
            unitTextFieldView.snp.makeConstraints {
                $0.leading.equalTo(quantityTextFieldView.snp.trailing).offset(8)
                $0.trailing.equalToSuperview().inset(16)
                $0.centerY.equalTo(quantityTextFieldView)
                $0.width.equalTo(80)
                $0.height.equalTo(44)
            }
            
            expirationLabel.snp.makeConstraints {
                $0.top.equalTo(quantityTextFieldView.snp.bottom).offset(16)
                $0.leading.equalToSuperview().inset(16)
            }

            dateTextField.snp.makeConstraints {
                $0.top.equalTo(expirationLabel.snp.bottom).offset(8)
                $0.horizontalEdges.equalToSuperview().inset(16)
                $0.bottom.equalToSuperview().inset(16)
                $0.height.equalTo(44)
            }
        }
    
    private func setupActions() {
        quantityTextFieldView.textField.addTarget(self, action: #selector(quantityTextFieldDidChange), for: .editingChanged)
        unitTextFieldView.textField.addTarget(self, action: #selector(unitTextFieldDidChange), for: .editingChanged)

        dateTextField.onDateSelected = { [weak self] date in
            self?.onDateSelected?(date)
        }
    }
    
    @objc private func quantityTextFieldDidChange() {
        onQuantityChanged?(quantityTextFieldView.textField.text ?? "")
    }
    
    @objc private func unitTextFieldDidChange() {
        onUnitChanged?(unitTextFieldView.textField.text ?? "")
    }
}
