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
        viewWillAppearTrigger.accept(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

        let detailVC = RecipeDetailViewController(
            recipe: data.recipe,
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
}
