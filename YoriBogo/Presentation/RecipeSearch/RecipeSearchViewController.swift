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

    // MARK: - Recent Search UI
    private let recentSearchContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let recentSearchHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let recentSearchLabel: UILabel = {
        let label = UILabel()
        label.text = "최근 검색어"
        label.font = AppFont.button
        label.textColor = .darkGray
        return label
    }()

    private let clearAllButton: UIButton = {
        let button = UIButton()
        button.setTitle("전체 삭제", for: .normal)
        button.setTitleColor(.systemGray, for: .normal)
        button.titleLabel?.font = AppFont.body
        return button
    }()

    private lazy var recentSearchCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsHorizontalScrollIndicator = false
        cv.register(RecentSearchChipCell.self, forCellWithReuseIdentifier: RecentSearchChipCell.id)
        return cv
    }()

    // MARK: - Properties
    private let viewModel = RecipeSearchViewModel()
    private let disposeBag = DisposeBag()
    private let recipeManager = RecipeRealmManager.shared
    private var searchResults: [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] = []
    private let deleteKeywordSubject = PublishSubject<String>()
    private let clearAllSubject = PublishSubject<Void>()
    private let manualSearchSubject = PublishSubject<String>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        setupGestures()
        bind()
        setupNotifications()

        emptyView.configure(state: .initial)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // DetailViewController에서 돌아올 때 북마크 상태 업데이트
        updateBookmarkStates()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        setNavigationTitle("레시피 검색")
    }

    func configureHierachy() {
        [searchBar, recentSearchContainerView, resultCountLabel, tableView, emptyView].forEach {
            view.addSubview($0)
        }

        recentSearchContainerView.addSubview(recentSearchHeaderView)
        recentSearchContainerView.addSubview(recentSearchCollectionView)

        [recentSearchLabel, clearAllButton].forEach {
            recentSearchHeaderView.addSubview($0)
        }
    }

    func configureLayout() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        // 최근 검색어 컨테이너
        recentSearchContainerView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(80)
        }

        // 최근 검색어 헤더
        recentSearchHeaderView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(32)
        }

        recentSearchLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        clearAllButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        // 최근 검색어 컬렉션뷰
        recentSearchCollectionView.snp.makeConstraints {
            $0.top.equalTo(recentSearchHeaderView.snp.bottom).offset(8)
            $0.horizontalEdges.bottom.equalToSuperview()
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
            $0.top.equalTo(recentSearchContainerView.snp.bottom)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recipeDidUpdate),
            name: .recipeDidUpdate,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recipeDidDelete),
            name: .recipeDidDelete,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recipeDidCreate),
            name: .recipeDidCreate,
            object: nil
        )
    }

    @objc private func recipeDidUpdate(_ notification: Notification) {
        // 레시피가 수정되면 검색 결과 업데이트
        guard let updatedRecipe = notification.userInfo?[Notification.RecipeKey.recipe] as? Recipe else { return }

        if let index = searchResults.firstIndex(where: { $0.recipe.id == updatedRecipe.id }) {
            let data = searchResults[index]
            searchResults[index].recipe = updatedRecipe

            // 해당 셀만 리로드
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    @objc private func recipeDidDelete(_ notification: Notification) {
        // 레시피가 삭제되면 검색 결과에서 제거
        guard let recipeId = notification.userInfo?[Notification.RecipeKey.recipeId] as? String else { return }

        if let index = searchResults.firstIndex(where: { $0.recipe.id == recipeId }) {
            searchResults.remove(at: index)
            tableView.reloadData()
        }
    }

    @objc private func recipeDidCreate(_ notification: Notification) {
        // 새 레시피가 생성되면 검색 재실행 (검색어가 있을 경우)
        guard !(searchBar.text ?? "").isEmpty else { return }

        // 검색바 텍스트를 재설정하여 검색 재실행
        let currentText = searchBar.text ?? ""
        searchBar.text = currentText
        searchBar.searchTextField.sendActions(for: .valueChanged)
    }

    // MARK: - Bind
    func bind() {
        // searchBar의 text와 수동 검색을 merge
        let searchText = Observable.merge(
            searchBar.rx.text.orEmpty.asObservable(),
            manualSearchSubject.asObservable()
        )

        let input = RecipeSearchViewModel.Input(
            searchText: searchText,
            searchButtonTapped: searchBar.rx.searchButtonClicked.asObservable(),
            deleteKeyword: deleteKeywordSubject.asObservable(),
            clearAllKeywords: clearAllSubject.asObservable()
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
                    self?.toggleBookmark(recipeId: recipeId)
                }
            }
            .disposed(by: disposeBag)

        // 최근 검색어 CollectionView에 바인딩
        output.recentSearches
            .drive(recentSearchCollectionView.rx.items(cellIdentifier: RecentSearchChipCell.id, cellType: RecentSearchChipCell.self)) { [weak self] index, keyword, cell in
                cell.configure(with: keyword)

                // 삭제 버튼 탭 이벤트 처리
                cell.onDeleteTapped = { keyword in
                    self?.deleteKeywordSubject.onNext(keyword)
                }
            }
            .disposed(by: disposeBag)

        // 최근 검색어 칩 선택 시 검색
        recentSearchCollectionView.rx.modelSelected(String.self)
            .subscribe(onNext: { [weak self] keyword in
                guard let self = self else { return }
                self.searchBar.text = keyword
                self.searchBar.resignFirstResponder()
                // 최근 검색어에 추가 (가장 최근으로 이동)
                RecentSearchManager.shared.addSearchKeyword(keyword)
                // 수동으로 검색 트리거
                self.manualSearchSubject.onNext(keyword)
            })
            .disposed(by: disposeBag)

        // 전체 삭제 버튼
        clearAllButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.clearAllSubject.onNext(())
            })
            .disposed(by: disposeBag)

        // 최근 검색어 UI 표시/숨김 처리
        Driver.combineLatest(output.recentSearches, output.isSearching)
            .drive(onNext: { [weak self] (recentSearches, isSearching) in
                guard let self = self else { return }

                let hasRecentSearches = !recentSearches.isEmpty

                // 검색 중이 아니고 최근 검색어가 있을 때만 표시
                let shouldShowRecentSearches = !isSearching && hasRecentSearches

                self.recentSearchContainerView.isHidden = !shouldShowRecentSearches
                self.clearAllButton.isHidden = !hasRecentSearches
            })
            .disposed(by: disposeBag)

        // 검색 결과 개수와 검색 상태를 함께 확인
        Driver.combineLatest(output.resultCount, output.isSearching)
            .drive(with: self) { owner, data in
                let (count, isSearching) = data

                if isSearching {
                    // 검색 중일 때
                    if count > 0 {
                        owner.resultCountLabel.text = "'\(owner.searchBar.text ?? "")' 검색 결과 \(count)개"
                        owner.resultCountLabel.isHidden = false
                        owner.tableView.isHidden = false
                        owner.emptyView.isHidden = true
                    } else {
                        owner.resultCountLabel.isHidden = true
                        owner.tableView.isHidden = true
                        owner.emptyView.isHidden = false
                        owner.emptyView.configure(state: .noResult)
                    }
                } else {
                    // 검색 중이 아닐 때 (검색어 비었을 때)
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

        // 검색 버튼 클릭 시 키보드 내리기
        searchBar.rx.searchButtonClicked
            .subscribe(onNext: { [weak self] in
                self?.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods
    private func toggleBookmark(recipeId: String) {
        do {
            // RecipeBookmarkManager를 사용하여 북마크 토글
            let updatedRecipe = try RecipeBookmarkManager.shared.toggleBookmark(recipeId: recipeId)

            // searchResults 배열에서 해당 레시피 찾아서 업데이트
            guard let index = searchResults.firstIndex(where: { $0.recipe.id == recipeId }) else { return }

            searchResults[index].recipe = updatedRecipe

            // 해당 셀 리로드
            if let visibleIndexPaths = tableView.indexPathsForVisibleRows,
               let indexPath = visibleIndexPaths.first(where: { $0.row == index }),
               let cell = tableView.cellForRow(at: indexPath) as? RecipeSearchCell {
                let data = searchResults[index]
                cell.configure(with: updatedRecipe, matchRate: data.matchRate)
            }
        } catch {
            showErrorAlert(title: "북마크 토글 실패", error: error)
        }
    }
}
