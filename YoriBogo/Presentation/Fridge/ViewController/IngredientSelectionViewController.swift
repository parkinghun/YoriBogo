//
//  IngredientSelectionView.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class IngredientSelectionViewController: BaseViewController, ConfigureViewController {
    
    enum Section: Int, CaseIterable {
        case category
        case ingredient
    }
    
    private lazy var categoryCollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: categoryLayout())
        cv.register(IngredientCategoryCell.self, forCellWithReuseIdentifier: IngredientCategoryCell.id)
        cv.delegate = self
        return cv
    }()
    lazy var ingredientCollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: ingredientLayout())
        cv.register(IngredientCell.self, forCellWithReuseIdentifier: IngredientCell.id)
        cv.register(IngredientHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: IngredientHeaderView.id)
        cv.backgroundColor = .gray50
        cv.delegate = self
        return cv
    }()
    let selectButton = RoundedButton(title: "재료 추가하기", titleColor: .white, backgroundColor: .brandOrange500)
    
    private let viewModel: IngredientSelectionViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    private let visibleSectionSubject = PublishSubject<Int>()
    
    private var isScrollingProgrammatically = false
    typealias CategorySection = IngredientSelectionViewModel.CategorySection
    
    private var categoryDataSource: UICollectionViewDiffableDataSource<CategorySection, FridgeCategory>!
    private var ingredientDataSource: UICollectionViewDiffableDataSource<FridgeSubcategory, FridgeIngredient>!
    
    
    init(viewModel: IngredientSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        configureDataSource()
        bind()
    }
    
    private func setupNavigation() {
        navigationItem.title = "재료 선택"
    }
    
    
    func configureHierachy() {
        view.addSubview(categoryCollectionView)
        view.addSubview(ingredientCollectionView)
        view.addSubview(selectButton)
    }
    
    func configureLayout() {
        categoryCollectionView.snp.makeConstraints {
            $0.verticalEdges.leading.equalTo(view.safeAreaLayoutGuide)
            $0.width.equalTo(100)
        }
        ingredientCollectionView.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(selectButton.snp.top).offset(-12)
            $0.leading.equalTo(categoryCollectionView.snp.trailing)
        }
        selectButton.snp.makeConstraints {
            $0.leading.equalTo(categoryCollectionView.snp.trailing).offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-30)
            $0.height.equalTo(44)
        }
    }
    
    
    func bind() {
        let input = IngredientSelectionViewModel.Input(selectedIngredientIndex: ingredientCollectionView.rx.itemSelected,
                                                       selectedCategoryIndex: categoryCollectionView.rx.itemSelected,
                                                       visibleSectionIndex: visibleSectionSubject.asObservable())
        let output = viewModel.transform(input: input)
        
        output.categories
            .drive(with: self) { owner, categories in
                owner.applyCategorySnapshot(categories)
            }
            .disposed(by: disposeBag)
        
        output.ingredientSections
            .drive(with: self) { owner, sections in
                owner.applyIngredientSnapshot(sections: sections)
            }
            .disposed(by: disposeBag)
        
        output.reconfigureItem
            .drive(with: self) { owner, ingredient in
                guard var snapshot = owner.ingredientDataSource?.snapshot() else { return }
                snapshot.reconfigureItems([ingredient])
                owner.ingredientDataSource?.apply(snapshot, animatingDifferences: false)
            }
            .disposed(by: disposeBag)
        
        // 카테고리 선택 시 재료 섹션 스크롤
        output.scrollToSection
            .drive(with: self) { owner, sectionIndex in
                owner.scrollToIngredientSection(sectionIndex)
            }
            .disposed(by: disposeBag)
        
        // 재료 스크롤 시 카테고리 선택
        output.selectedCategoryIndex
            .drive(with: self) { owner, categoryIndex in
                owner.selectCategory(at: categoryIndex)
            }
            .disposed(by: disposeBag)
        
        output.buttonTitle
            .drive(selectButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        output.isButtonEnabled
            .drive(with: self) { owner, isEnabled in
                owner.selectButton.isEnabled = isEnabled
                owner.selectButton.backgroundColor = isEnabled ? .brandOrange500 : .gray300
                owner.selectButton.alpha = isEnabled ? 1.0 : 0.6
            }
            .disposed(by: disposeBag)
        
        selectButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let selectedIngredients = owner.viewModel.getSelectedIngredients()
                owner.navigateToDetail(with: selectedIngredients)
            })
            .disposed(by: disposeBag)
    }
    
    private func navigateToDetail(with ingredients: [FridgeIngredient]) {
        dump(ingredients)
        let detailViewModel = IngredientDetailInputViewModel(ingredients: ingredients)
        let detailVC = IngredientDetailInputViewController(viewModel: detailViewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func configureDataSource() {
        categoryDataSource = UICollectionViewDiffableDataSource<CategorySection, FridgeCategory>(collectionView: categoryCollectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientCategoryCell.id, for: indexPath) as? IngredientCategoryCell else { return UICollectionViewCell() }
            
            let icon = UIImage(named: item.imageName)
            cell.configure(icon: icon, title: item.name, selected: false)
            return cell
        }
        
        ingredientDataSource = UICollectionViewDiffableDataSource<FridgeSubcategory, FridgeIngredient>(collectionView: ingredientCollectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientCell.id, for: indexPath) as? IngredientCell else { return UICollectionViewCell() }

            let image = UIImage.ingredientImage(imageKey: item.key, categoryId: item.categoryId)

            let isSelected = self.viewModel.isIngredientSelected(item.id)
            cell.configure(image: image, title: item.name, isSelected: isSelected)

            return cell
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<IngredientHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] header, _, indexPath in
            guard let self = self,
                  let snapshot = self.ingredientDataSource?.snapshot() else { return }
            
            let sectionId = snapshot.sectionIdentifiers[indexPath.section]
            header.configure(title: sectionId.name)
        }
        
        ingredientDataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func applyCategorySnapshot(_ categories: [FridgeCategory], animating: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<CategorySection, FridgeCategory>()
        snapshot.appendSections([.main])
        snapshot.appendItems(categories, toSection: .main)
        categoryDataSource.apply(snapshot, animatingDifferences: animating)
        
        // 첫 번째 카테고리 자동 선택
        if !categories.isEmpty {
            let indexPath = IndexPath(item: 0, section: 0)
            categoryCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }
    
    private func applyIngredientSnapshot(sections: [IngredientSelectionViewModel.IngredientSectionModel], animating: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<FridgeSubcategory, FridgeIngredient>()
        // 각 서브카테고리를 하나의 섹션으로(헤더 없이 섹션만 구분)
        for section in sections {
            snapshot.appendSections([section.header])
            snapshot.appendItems(section.items, toSection: section.header)
        }
        ingredientDataSource.apply(snapshot, animatingDifferences: animating)
    }
    
    private func scrollToIngredientSection(_ sectionIndex: Int) {
        isScrollingProgrammatically = true
        
        let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
        
        if let headerAttributes = ingredientCollectionView.layoutAttributesForSupplementaryElement(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: headerIndexPath
        ) {
            let offsetY = headerAttributes.frame.origin.y - ingredientCollectionView.contentInset.top
            ingredientCollectionView.setContentOffset(
                CGPoint(x: 0, y: offsetY),
                animated: true
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isScrollingProgrammatically = false
        }
    }
    
    private func selectCategory(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        
        // 이전 선택 해제
        if let selectedItems = categoryCollectionView.indexPathsForSelectedItems {
            selectedItems.forEach { categoryCollectionView.deselectItem(at: $0, animated: false) }
        }
        
        // 새로운 선택
        categoryCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        categoryCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }
    
    /// 현재 보이는 재료 섹션 감지
    private func updateVisibleSection() {
        guard !isScrollingProgrammatically else { return }
        
        let visibleIndexPaths = ingredientCollectionView.indexPathsForVisibleItems.sorted()
        
        guard let firstVisibleIndexPath = visibleIndexPaths.first else { return }
        
        visibleSectionSubject.onNext(firstVisibleIndexPath.section)
    }
    
    
    private func categoryLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.8))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
    
    private func ingredientLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
        
        section.boundarySupplementaryItems = [header]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}

extension IngredientSelectionViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == ingredientCollectionView else { return }
        updateVisibleSection()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == ingredientCollectionView else { return }
        updateVisibleSection()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == ingredientCollectionView, !decelerate else { return }
        updateVisibleSection()
    }
}
