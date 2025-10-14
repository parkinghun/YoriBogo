//
//  RecipeViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class RecipeViewController: BaseViewController {

    // MARK: - UI Components
    private let segmentControl: UISegmentedControl = {
        let items = [RecipeTab.bookmarked.title, RecipeTab.myRecipes.title]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = 0
        return segment
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .gray50
        cv.register(RecipeCell.self, forCellWithReuseIdentifier: RecipeCell.id)
        cv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        cv.alwaysBounceHorizontal = false
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()

    private let emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "book.closed")
        iv.tintColor = .gray300
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "북마크한 레시피가 없습니다"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray500
        label.textAlignment = .center
        return label
    }()
    
    private let addButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)

    // MARK: - Properties
    private let viewModel = RecipeViewModel()
    private let disposeBag = DisposeBag()
    private let refreshTrigger = PublishRelay<Void>()
    private var currentTab: RecipeTab = .bookmarked

    private var dataSource: UICollectionViewDiffableDataSource<Section, Recipe>!

    enum Section {
        case main
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        configureDataSource()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTrigger.accept(())
    }

    // MARK: - Setup
    private func setupNavigation() {
        setNavigationTitle("나의 레시피")
        addNavigationBarButton(addButtonItem, position: .right)
    }

    private func setupUI() {
        view.addSubview(segmentControl)
        view.addSubview(collectionView)
        view.addSubview(emptyView)

        emptyView.addSubview(emptyImageView)
        emptyView.addSubview(emptyLabel)

        segmentControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(32)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(segmentControl.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.snp.makeConstraints {
            $0.edges.equalTo(collectionView)
        }

        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-40)
            $0.size.equalTo(80)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        return CompositionalLayoutFactory.createVerticalListLayout(
            estimatedHeight: 120,
            spacing: 12,
            contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        )
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Recipe>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, recipe in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RecipeCell.id,
                    for: indexPath
                  ) as? RecipeCell else {
                return UICollectionViewCell()
            }

            // 현재 선택된 탭에 따라 북마크 버튼 표시 여부 결정
            let isBookmarkTab = self.currentTab == .bookmarked
            cell.configure(with: recipe, showBookmark: isBookmarkTab)

            // 북마크 버튼 처리
            cell.onBookmarkTapped = { [weak self] recipeId in
                self?.handleBookmarkTap(recipeId: recipeId)
            }

            return cell
        }

        // Cell 선택 시 상세 화면으로 이동
        collectionView.rx.itemSelected
            .subscribe(with: self) { owner, indexPath in
                guard let recipe = owner.dataSource.itemIdentifier(for: indexPath) else { return }
                owner.navigateToDetail(recipe: recipe)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Bind
    private func bind() {
        let input = RecipeViewModel.Input(
            viewDidLoad: Observable.just(()),
            segmentChanged: segmentControl.rx.selectedSegmentIndex.asObservable(),
            refreshTrigger: refreshTrigger.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 선택된 탭
        output.selectedTab
            .drive(with: self) { owner, tab in
                owner.currentTab = tab
                // 탭이 변경되면 현재 snapshot의 모든 아이템을 reconfigure
                owner.reconfigureVisibleCells()
            }
            .disposed(by: disposeBag)

        // 레시피 목록
        output.recipes
            .drive(with: self) { owner, recipes in
                owner.applySnapshot(recipes)
            }
            .disposed(by: disposeBag)

        // 빈 상태
        output.isEmpty
            .drive(with: self) { owner, isEmpty in
                owner.emptyView.isHidden = !isEmpty
                owner.collectionView.isHidden = isEmpty
            }
            .disposed(by: disposeBag)

        // 빈 상태 메시지
        output.emptyMessage
            .drive(with: self) { owner, message in
                owner.emptyLabel.text = message
            }
            .disposed(by: disposeBag)

        // 레시피 추가 버튼
        addButtonItem.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.presentRecipeAddView()
            }
            .disposed(by: disposeBag)
    }

    private func applySnapshot(_ recipes: [Recipe]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Recipe>()
        snapshot.appendSections([.main])
        snapshot.appendItems(recipes)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func reconfigureVisibleCells() {
        guard var snapshot = dataSource?.snapshot() else { return }

        // 현재 snapshot의 모든 아이템을 reload
        let allItems = snapshot.itemIdentifiers
        if !allItems.isEmpty {
            if #available(iOS 15.0, *) {
                snapshot.reconfigureItems(allItems)
                dataSource.apply(snapshot, animatingDifferences: false)
            } else {
                snapshot.reloadItems(allItems)
                dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }

    // MARK: - Actions
    private func handleBookmarkTap(recipeId: String) {
        do {
            _ = try RecipeBookmarkManager.shared.toggleBookmark(recipeId: recipeId)
            refreshTrigger.accept(())
        } catch {
            showErrorAlert(title: "북마크 실패", error: error)
        }
    }

    private func navigateToDetail(recipe: Recipe) {
        let vc = RecipeDetailViewController(recipe: recipe, matchRate: 0, matchedIngredients: [])
        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentRecipeAddView() {
        let vc = RecipeAddViewController()
        let nav = BaseNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
