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
    
    // listConfiguration
    private lazy var categoryCollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: categoryLayout())
        cv.register(IngredientCategoryCell.self, forCellWithReuseIdentifier: IngredientCategoryCell.id)
        return cv
    }()
    lazy var ingredientCollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: ingredientLayout())
        cv.register(IngredientCell.self, forCellWithReuseIdentifier: IngredientCell.id)
        cv.register(IngredientHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: IngredientHeaderView.id)
        cv.backgroundColor = .gray50
        return cv
    }()
    let selectButton = RoundedButton(title: "재료 추가하기", titleColor: .white, backgroundColor: .brandOrange500)
    
    private let viewModel: IngredientSelectionViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    
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
        let input = IngredientSelectionViewModel.Input(selectedIngredientIndex: ingredientCollectionView.rx.itemSelected)
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
        
        output.selectedItemIds
            .drive(with: self) { owner, ids in
                
            }
            .disposed(by: disposeBag)
            
    }
    
    private func configureDataSource() {
        categoryDataSource = UICollectionViewDiffableDataSource<CategorySection, FridgeCategory>(collectionView: categoryCollectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientCategoryCell.id, for: indexPath) as? IngredientCategoryCell else { return UICollectionViewCell() }
            
            let icon = UIImage(systemName: item.imageName)
            cell.configure(icon: icon, title: item.name, selected: false)
            return cell
        }
        
        ingredientDataSource = UICollectionViewDiffableDataSource<FridgeSubcategory, FridgeIngredient>(collectionView: ingredientCollectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientCell.id, for: indexPath) as? IngredientCell else { return UICollectionViewCell() }
            
            let image = UIImage(named: item.key)
            cell.configure(image: image, title: item.name)
            
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
    
    private func applyCategorySnapshot(_ categories: [FridgeCategory], animating: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<CategorySection, FridgeCategory>()
        snapshot.appendSections([.main])
        snapshot.appendItems(categories, toSection: .main)
        categoryDataSource.apply(snapshot, animatingDifferences: animating)
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
