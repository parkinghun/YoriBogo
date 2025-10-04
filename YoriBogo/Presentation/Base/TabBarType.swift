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
    case search
//    case myRecipe
//    case setting
    
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
        case .search:
            let vc = RecipeSearchViewController()
            vc.tabBarItem = self.tabBarItem
            return vc
//        case .myRecipe:
//            let vc = RecipeViewController()
//            vc.tabBarItem = self.tabBarItem
//            return vc
//        case .setting:
//            let vc = SettingViewController()
//            vc.tabBarItem = self.tabBarItem
//            return vc
        }
    }
    
    private var tabBarItem: UITabBarItem {
        switch self {
        case .refrigerator:
            return UITabBarItem(title: title, image: itemImage, tag: 0)
        case .recommend:
            return UITabBarItem(title: title, image: itemImage, tag: 1)
        case .search:
            return UITabBarItem(title: title, image: itemImage, tag: 2)
//        case .myRecipe:
//            return UITabBarItem(title: title, image: itemImage, tag: 2)
//        case .setting:
//            return UITabBarItem(title: title, image: itemImage, tag: 3)
        }
    }
    
    private var title: String? {
        switch self {
        case .refrigerator:
            return "냉장고"
        case .recommend:
            return "추천"
        case .search:
            return "검색"
//        case .myRecipe:
//            return "나의 레시피"
//        case .setting:
//            return "설정"
        }
    }
    
    private var itemImage: UIImage? {
        switch self {
        case .refrigerator:
            return UIImage(systemName: "refrigerator")
        case .recommend:
            return UIImage(systemName: "text.book.closed")
        case .search:
            return UIImage(systemName: "magnifyingglass")
//        case .myRecipe:
//            return UIImage(systemName: "fork.knife")
//        case .setting:
//            return UIImage(systemName: "gearshape")
        }
    }
}

