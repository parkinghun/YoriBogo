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

    // MARK: - UI Components
    private let searchBar: UISearchBar = {
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

    private let resultCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.button
        label.textColor = .systemGray
        label.isHidden = true
        return label
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .white
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.rowHeight = 132
        tv.register(RecipeSearchCell.self, forCellReuseIdentifier: RecipeSearchCell.id)
        tv.keyboardDismissMode = .onDrag
        tv.isHidden = true
        return tv
    }()

    private let emptyView = RecipeSearchEmptyView()

    // MARK: - Properties
    private let viewModel = RecipeSearchViewModel()
    private let disposeBag = DisposeBag()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        bind()

        emptyView.configure(state: .initial)
    }

    // MARK: - Setup
    private func setupNavigation() {
        navigationItem.title = "레시피 검색"
    }

    func configureHierachy() {
        [searchBar, resultCountLabel, tableView, emptyView].forEach {
            view.addSubview($0)
        }
    }

    func configureLayout() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        resultCountLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(resultCountLabel.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Bind
    func bind() {
        let input = RecipeSearchViewModel.Input(
            searchText: searchBar.rx.text.orEmpty.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 검색 결과
        output.searchResults
            .drive(tableView.rx.items(cellIdentifier: RecipeSearchCell.id, cellType: RecipeSearchCell.self)) { index, data, cell in
                cell.configure(with: data.recipe, matchRate: data.matchRate)
            }
            .disposed(by: disposeBag)

        // 검색 결과 개수
        output.resultCount
            .drive(with: self) { owner, count in
                if count > 0 {
                    owner.resultCountLabel.text = "'\(owner.searchBar.text ?? "")' 검색 결과 \(count)개"
                    owner.resultCountLabel.isHidden = false
                    owner.tableView.isHidden = false
                    owner.emptyView.isHidden = true
                } else if !(owner.searchBar.text ?? "").isEmpty {
                    owner.resultCountLabel.isHidden = true
                    owner.tableView.isHidden = true
                    owner.emptyView.isHidden = false
                    owner.emptyView.configure(state: .noResult)
                } else {
                    owner.resultCountLabel.isHidden = true
                    owner.tableView.isHidden = true
                    owner.emptyView.isHidden = false
                    owner.emptyView.configure(state: .initial)
                }
            }
            .disposed(by: disposeBag)

        // 셀 선택
        tableView.rx.modelSelected((recipe: Recipe, matchRate: Double, matchedIngredients: [String]).self)
            .subscribe(onNext: { [weak self] data in
                let detailVC = RecipeDetailViewController(
                    recipe: data.recipe,
                    matchRate: data.matchRate,
                    matchedIngredients: data.matchedIngredients
                )
                self?.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
