//
//  BorderedTextFieldView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import UIKit
import SnapKit

final class BorderedTextFieldView: UIView {
    enum TextFieldType {
        case quantity
        case unit
        case date
    }
    
    let textField = UITextField()
    let calendarButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "calendar"), for: .normal)
        button.tintColor = .gray600
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    init(type: TextFieldType) {
        super.init(frame: .zero)
        setupUI(type: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(type: TextFieldType) {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.borderColor = UIColor.gray200.cgColor
        layer.borderWidth = 1
        
        textField.font = AppFont.button
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        
        self.addSubview(textField)
        
        switch type {
        case .quantity:
            textField.placeholder = "1"
            textField.keyboardType = .decimalPad
            
            textField.snp.makeConstraints {
                $0.verticalEdges.equalToSuperview().inset(12)
                $0.horizontalEdges.equalToSuperview().inset(12)
            }
            
        case .unit:
            textField.placeholder = "개"
            textField.textAlignment = .center
            
            textField.snp.makeConstraints {
                $0.verticalEdges.equalToSuperview().inset(12)
                $0.horizontalEdges.equalToSuperview().inset(12)
            }
            
        case .date:
            textField.placeholder = DateFormatter.expirationDate.string(from: .now)
            textField.tintColor = .clear  // 커서 숨기기
            
            addSubview(calendarButton)
            
            textField.snp.makeConstraints {
                $0.verticalEdges.equalToSuperview().inset(12)
                $0.leading.equalToSuperview().inset(12)
                $0.trailing.equalTo(calendarButton.snp.leading).offset(-8)
            }
            
            calendarButton.snp.makeConstraints {
                $0.trailing.equalToSuperview().inset(12)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(24)
            }
        }
    }
}
