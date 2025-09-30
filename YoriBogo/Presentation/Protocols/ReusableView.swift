//
//  ReusableView.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

protocol ReusableView {
    static var id: String { get }
}

extension ReusableView {
    static var id: String { String(describing: Self.self) }
}
