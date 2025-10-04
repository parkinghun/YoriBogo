//
//  RecipeSearchViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher

final class RecipeSearchViewController: BaseViewController, ConfigureViewController {
    
    //TODO: - 서치바
    let searchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "원하는 요리, 재료를 검색해주세요"
        searchBar.searchTextField.borderStyle = .none
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.font = AppFont.body
        searchBar.backgroundColor = .gray100
        searchBar.layer.cornerRadius = 12
        searchBar.becomeFirstResponder()
        return searchBar
    }()
    
    //TODO: - 컬렉션 뷰
    //TODO: - EmptyView
    let emptyView = RecipeSearchEmptyView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        bind()
        
        emptyView.configure(state: .initial)
    }
    
    private func setupNavigation() {
        navigationItem.title = "레시피 검색"
    }
    
    func configureHierachy() {
        view.addSubview(searchBar)
        view.addSubview(emptyView)
    }
    
    func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func bind() {
        
    }
}
