//
//  BaseCollectionViewCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

final class BaseCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureBgColor()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureBgColor() {
        contentView.backgroundColor = .white
    }
    
}
