//
//  RoundedButton.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

final class RoundedButton: UIButton {
    
    convenience init(title: String, titleColor: UIColor = .white, font: UIFont = AppFont.button, image: UIImage? = nil, backgroundColor: UIColor) {
        self.init()
        self.setTitle(title, for: .normal)
        self.setTitleColor(titleColor, for: .normal)
        self.titleLabel?.font = font
        self.setImage(image, for: .normal)
        self.backgroundColor = backgroundColor
        
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
    }
}

