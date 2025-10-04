//
//  RecommendViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher

final class RecommendViewController: BaseViewController {

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "지금 냉장고에 딱 맞는 레시피"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .darkGray
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "보유 재료로 만들 수 있는 추천 요리 TOP 5"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGray
        return label
    }()

    private let searchButtonItem = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: nil, action: nil)

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createCompositionalLayout())
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast
        cv.register(RecommendRecipeCell.self, forCellWithReuseIdentifier: RecommendRecipeCell.id)
        cv.alwaysBounceVertical = false
        return cv
    }()

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 5
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.currentPageIndicatorTintColor = .systemOrange
        pageControl.isHidden = true
        return pageControl
    }()
    
    // MARK: - Properties
    private let viewModel = RecommendViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppearTrigger = PublishRelay<Void>()
    private let recipeManager = RecipeRealmManager.shared

    private var recommendedData: [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] = []
    private var hasIngredients: Bool = true

    private var autoScrollTimer: Timer?
    private let multiplier = 100 // 무한 스크롤을 위한 multiplier

    // MARK: - Compositional Layout
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.7),
            heightDimension: .fractionalHeight(0.75)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 0

        section.visibleItemsInvalidationHandler = { items, offset, environment in
            let centerX = offset.x + environment.container.contentSize.width / 2
            for item in items {
                let distance = abs(item.frame.midX - centerX)
                let scale = max(0.85, 1 - (distance / environment.container.contentSize.width) * 0.25)
                item.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
        
        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigation()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // DetailViewController에서 돌아올 때 북마크 상태 업데이트
        if !recommendedData.isEmpty {
            updateBookmarkStates()
        } else {
            // 처음 진입할 때만 데이터 로드
            viewWillAppearTrigger.accept(())
        }
    }

    private func updateBookmarkStates() {
        // Realm에서 최신 recipe 가져와서 recommendedData 업데이트
        for (index, data) in recommendedData.enumerated() {
            if let updatedRecipe = recipeManager.fetchRecipe(by: data.recipe.id) {
                recommendedData[index].recipe = updatedRecipe
            }
        }

        // 보이는 셀들만 업데이트
        collectionView.visibleCells.forEach { cell in
            if let indexPath = collectionView.indexPath(for: cell),
               let recipeCell = cell as? RecommendRecipeCell {
                let actualIndex = indexPath.item % recommendedData.count
                let data = recommendedData[actualIndex]
                recipeCell.configure(
                    with: data.recipe,
                    hasIngredients: hasIngredients,
                    matchRate: data.matchRate,
                    matchedIngredients: data.matchedIngredients
                )

                // 북마크 클로저 다시 연결
                recipeCell.onBookmarkTapped = { [weak self] recipeId in
                    self?.toggleBookmark(recipeId: recipeId)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // collectionView가 보이는지 확인
        if recommendedData.isEmpty {
            print("⚠️ RecommendViewController - 데이터가 비어있습니다")
        }

        startAutoScroll()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    deinit {
        stopAutoScroll()
    }
    
    // MARK: - Setup
    private func setNavigation() {
        navigationItem.title = "레시피 추천"
        navigationItem.rightBarButtonItem = searchButtonItem
        searchButtonItem.isHidden = true
    }
    
    private func setupUI() {
//        view.backgroundColor = .beige100
        view.backgroundColor = .white
        
        [titleLabel, subtitleLabel, collectionView, pageControl].forEach {
            view.addSubview($0)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(pageControl.snp.top).offset(-20)
        }

        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(30)
        }

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    // MARK: - Bind
    private func bind() {
        let input = RecommendViewModel.Input(
            viewWillAppear: viewWillAppearTrigger.asObservable(),
            searchButtonTapped: searchButtonItem.rx.tap
        )

        let output = viewModel.transform(input: input)

        output.recommendedRecipes
            .drive(with: self) { owner, data in
                owner.recommendedData = data
                owner.pageControl.numberOfPages = data.count
                owner.collectionView.reloadData()

                // 중앙으로 스크롤 (무한 스크롤을 위해)
                if !data.isEmpty {
                    let centerIndex = owner.multiplier / 2 * data.count
                    DispatchQueue.main.async {
                        owner.collectionView.scrollToItem(
                            at: IndexPath(item: centerIndex, section: 0),
                            at: .centeredHorizontally,
                            animated: false
                        )
                    }
                }
            }
            .disposed(by: disposeBag)

        output.hasIngredients
            .drive(with: self) { owner, hasIngredients in
                owner.hasIngredients = hasIngredients
                if hasIngredients {
                    owner.subtitleLabel.text = "보유 재료로 만들 수 있는 추천 요리 TOP 5"
                } else {
                    owner.subtitleLabel.text = "냉장고가 비어있어요. 이런 요리는 어때요?"
                }
            }
            .disposed(by: disposeBag)
        
        output.pushSearchViewController
            .drive(with: self) { owner, _ in
                let vc = RecipeSearchViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Auto Scroll
    // TODO: - 타이머 / 페이지 컨트롤 수정
    private func startAutoScroll() {
        stopAutoScroll()
        guard !recommendedData.isEmpty else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.scrollToNextItem()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func currentCenteredIndexPath() -> IndexPath? {
        let center = collectionView.bounds.midX + collectionView.contentOffset.x
        let centerPoint = CGPoint(x: center, y: collectionView.bounds.midY)
        return collectionView.indexPathForItem(at: centerPoint)
    }
}

// MARK: - UICollectionViewDataSource
extension RecommendViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !recommendedData.isEmpty else { return 0 }
        return recommendedData.count * multiplier // 무한 스크롤
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RecommendRecipeCell.id,
            for: indexPath
        ) as? RecommendRecipeCell else {
            return UICollectionViewCell()
        }

        let actualIndex = indexPath.item % recommendedData.count
        let data = recommendedData[actualIndex]

        cell.configure(
            with: data.recipe,
            hasIngredients: hasIngredients,
            matchRate: data.matchRate,
            matchedIngredients: data.matchedIngredients
        )

        // 북마크 버튼 탭 이벤트 처리
        cell.onBookmarkTapped = { [weak self] recipeId in
            print("🎯 RecommendViewController - 북마크 클로저 호출됨")
            self?.toggleBookmark(recipeId: recipeId)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension RecommendViewController: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 스크롤 중에도 실시간으로 페이지 컨트롤 업데이트
        updatePageControl()
//        startAutoScroll()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 사용자가 스크롤을 시작하면 자동 스크롤 중지
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePageControl()
        startAutoScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updatePageControl()
    }
    
    private func scrollToNextItem() {
        guard !recommendedData.isEmpty else { return }
        guard let currentIndexPath = currentCenteredIndexPath() else { return }

        let nextItem = (currentIndexPath.item + 1) % (recommendedData.count * multiplier)
        let nextIndexPath = IndexPath(item: nextItem, section: 0)
        collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)

        // ✅ 페이지 컨트롤 갱신 추가
        pageControl.currentPage = nextItem % recommendedData.count
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 사용자가 스크롤을 끝내면 타이머 리셋하여 4초 후 자동 스크롤 재시작
        if !decelerate {
            updatePageControl()
            startAutoScroll()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let actualIndex = indexPath.item % recommendedData.count
        let data = recommendedData[actualIndex]

        // Realm에서 최신 레시피 가져오기
        guard let updatedRecipe = recipeManager.fetchRecipe(by: data.recipe.id) else {
            print("⚠️ 레시피를 찾을 수 없습니다: \(data.recipe.id)")
            return
        }

        let detailVC = RecipeDetailViewController(
            recipe: updatedRecipe,
            matchRate: data.matchRate,
            matchedIngredients: data.matchedIngredients
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func updatePageControl() {
        guard !recommendedData.isEmpty else { return }

        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        let centerPoint = CGPoint(x: centerX, y: collectionView.bounds.midY)

        if let indexPath = collectionView.indexPathForItem(at: centerPoint) {
            pageControl.currentPage = indexPath.item % recommendedData.count
        }
    }

    private func toggleBookmark(recipeId: String) {
        print("📌 toggleBookmark 호출됨: \(recipeId)")
        do {
            // Realm에서 북마크 토글
            try recipeManager.toggleBookmark(recipeId: recipeId)
            print("✅ 북마크 토글 성공")

            // recommendedData 배열에서 해당 레시피 찾아서 업데이트
            for (index, data) in recommendedData.enumerated() {
                if data.recipe.id == recipeId {
                    // 업데이트된 레시피 가져오기
                    if let updatedRecipe = recipeManager.fetchRecipe(by: recipeId) {
                        recommendedData[index].recipe = updatedRecipe

                        // 모든 해당 셀들 리로드 (무한 스크롤이므로 여러 인덱스에 같은 데이터가 있음)
                        collectionView.visibleCells.forEach { cell in
                            if let indexPath = collectionView.indexPath(for: cell),
                               let recipeCell = cell as? RecommendRecipeCell {
                                let actualIndex = indexPath.item % recommendedData.count
                                if actualIndex == index {
                                    recipeCell.configure(
                                        with: updatedRecipe,
                                        hasIngredients: hasIngredients,
                                        matchRate: data.matchRate,
                                        matchedIngredients: data.matchedIngredients
                                    )
                                }
                            }
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
