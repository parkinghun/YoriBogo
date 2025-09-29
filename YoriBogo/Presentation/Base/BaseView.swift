//
//  BaseView.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

class BaseView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setBackgroundColor()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setBackgroundColor() {
        backgroundColor = .white
    }
}
