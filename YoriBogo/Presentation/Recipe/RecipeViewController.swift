//
//  RecipeViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

final class RecipeViewController: BaseViewController {
    
    private let recipeTableView: UITableView = {
        let tv = UITableView()
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
    }

    private func setupNavigation() {
        setNavigationTitle("나의 레시피")
    }
}
