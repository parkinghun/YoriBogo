//
//  TabBarType.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

enum TabBarType: CaseIterable {
    case refrigerator
    case recommend
    case myRecipe
    case setting
    
    var navigationController: UINavigationController {
        return BaseNavigationController(rootViewController: viewController)
    }
    
    private var viewController: UIViewController {
        switch self {
        case .refrigerator:
            let vc = FridgeViewController(viewModel: FridgeViewModel())
            vc.tabBarItem = self.tabBarItem
            return vc
        case .recommend:
            let vc = RecommendViewController()
            vc.tabBarItem = self.tabBarItem
            return vc
        case .myRecipe:
            let vc = RecipeViewController()
            vc.tabBarItem = self.tabBarItem
            return vc
        case .setting:
            let vc = SettingViewController()
            vc.tabBarItem = self.tabBarItem
            return vc
        }
    }
    
    private var tabBarItem: UITabBarItem {
        switch self {
        case .refrigerator:
            return UITabBarItem(title: title, image: itemImage, tag: 0)
        case .recommend:
            return UITabBarItem(title: title, image: itemImage, tag: 1)
        case .myRecipe:
            return UITabBarItem(title: title, image: itemImage, tag: 2)
        case .setting:
            return UITabBarItem(title: title, image: itemImage, tag: 3)
        }
    }
    
    private var title: String? {
        switch self {
        case .refrigerator:
            return "냉장고"
        case .recommend:
            return "추천"
        case .myRecipe:
            return "나의 레시피"
        case .setting:
            return "설정"
        }
    }
    
    private var itemImage: UIImage? {
        switch self {
        case .refrigerator:
            return UIImage(systemName: "refrigerator")
        case .recommend:
            return UIImage(systemName: "fork.knife")
        case .myRecipe:
            return UIImage(systemName: "text.book.closed")
        case .setting:
            return UIImage(systemName: "gearshape")
        }
    }
}

