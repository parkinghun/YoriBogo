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
    private let recipeManager = RecipeRealmManager.shared
    private var searchResults: [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        bind()

        emptyView.configure(state: .initial)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // DetailViewController에서 돌아올 때 북마크 상태 업데이트
        updateBookmarkStates()
    }

    private func updateBookmarkStates() {
        guard !searchResults.isEmpty else { return }

        // Realm에서 최신 recipe 가져와서 searchResults 업데이트
        for (index, data) in searchResults.enumerated() {
            if let updatedRecipe = recipeManager.fetchRecipe(by: data.recipe.id) {
                searchResults[index].recipe = updatedRecipe
            }
        }

        // 보이는 셀들만 업데이트
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            visibleIndexPaths.forEach { indexPath in
                if let cell = tableView.cellForRow(at: indexPath) as? RecipeSearchCell,
                   indexPath.row < searchResults.count {
                    let data = searchResults[indexPath.row]
                    cell.configure(with: data.recipe, matchRate: data.matchRate)

                    // 북마크 클로저 다시 연결
                    cell.onBookmarkTapped = { [weak self] recipeId in
                        self?.toggleBookmark(recipeId: recipeId)
                    }
                }
            }
        }
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

        // 검색 결과 저장
        output.searchResults
            .drive(with: self) { owner, results in
                owner.searchResults = results
            }
            .disposed(by: disposeBag)

        // 검색 결과 tableView에 바인딩
        output.searchResults
            .drive(tableView.rx.items(cellIdentifier: RecipeSearchCell.id, cellType: RecipeSearchCell.self)) { [weak self] index, data, cell in
                cell.configure(with: data.recipe, matchRate: data.matchRate)

                // 북마크 버튼 탭 이벤트 처리
                cell.onBookmarkTapped = { recipeId in
                    print("🎯 RecipeSearchViewController - 북마크 클로저 호출됨")
                    self?.toggleBookmark(recipeId: recipeId)
                }
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
                guard let self = self else { return }

                // Realm에서 최신 레시피 가져오기
                guard let updatedRecipe = self.recipeManager.fetchRecipe(by: data.recipe.id) else {
                    print("⚠️ 레시피를 찾을 수 없습니다: \(data.recipe.id)")
                    return
                }

                let detailVC = RecipeDetailViewController(
                    recipe: updatedRecipe,
                    matchRate: data.matchRate,
                    matchedIngredients: data.matchedIngredients
                )
                self.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods
    private func toggleBookmark(recipeId: String) {
        print("📌 검색 화면 toggleBookmark 호출됨: \(recipeId)")
        do {
            // Realm에서 북마크 토글
            try recipeManager.toggleBookmark(recipeId: recipeId)
            print("✅ 북마크 토글 성공")

            // searchResults 배열에서 해당 레시피 찾아서 업데이트
            for (index, data) in searchResults.enumerated() {
                if data.recipe.id == recipeId {
                    // 업데이트된 레시피 가져오기
                    if let updatedRecipe = recipeManager.fetchRecipe(by: recipeId) {
                        searchResults[index].recipe = updatedRecipe

                        // 해당 셀 리로드
                        if let visibleIndexPaths = tableView.indexPathsForVisibleRows,
                           let indexPath = visibleIndexPaths.first(where: { $0.row == index }),
                           let cell = tableView.cellForRow(at: indexPath) as? RecipeSearchCell {
                            cell.configure(with: updatedRecipe, matchRate: data.matchRate)
                        }
                    }
                    break
                }
            }
        } catch {
            print("❌ 북마크 토글 에러: \(error)")
        }
    }
}
