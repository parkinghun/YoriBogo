//
//  UIViewController+Navigation.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-09.
//

import UIKit

enum NavigationBarPosition {
    case left
    case right
}

extension UIViewController {
    /// Navigation Title을 설정
    func setNavigationTitle(_ title: String) {
        navigationItem.title = title
    }

    /// Navigation Bar Button을 설정
    func addNavigationBarButton(_ button: UIBarButtonItem, position: NavigationBarPosition) {
        switch position {
        case .left:
            navigationItem.leftBarButtonItem = button
        case .right:
            navigationItem.rightBarButtonItem = button
        }
    }

    /// Navigation Bar에 여러 버튼을 설정
    func addNavigationBarButtons(_ buttons: [UIBarButtonItem], position: NavigationBarPosition) {
        switch position {
        case .left:
            navigationItem.leftBarButtonItems = buttons
        case .right:
            navigationItem.rightBarButtonItems = buttons
        }
    }
}
