//
//  BaseTabBarController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

final class BaseTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setTabBar()
    }
    
    private func setTabBar() {
        self.viewControllers = TabBarType.allCases.map { $0.navigationController }
        
        self.tabBar.tintColor = .black
        self.tabBar.unselectedItemTintColor = .gray
    }
}

