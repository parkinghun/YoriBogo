//
//  IngredientSelectionViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa

final class IngredientSelectionViewModel: ViewModelType {
    
    enum CategorySection: Hashable {
        case main
    }
    
    struct IngredientSectionModel: Hashable {
        let header: FridgeSubcategory
        let items: [FridgeIngredient]
    }
    
    struct Input {
        let selectedIngredientIndex: ControlEvent<IndexPath>
        let selectedCategoryIndex: ControlEvent<IndexPath>
        let visibleSectionIndex: Observable<Int>  // 재료 스크롤 시 현재 어떤 섹션이 보이는가
    }
    
    struct Output {
        let categories: Driver<[FridgeCategory]>
        let ingredientSections: Driver<[IngredientSectionModel]>
        let scrollToSection: Driver<Int>
        let selectedCategoryIndex: Driver<Int>
        let reconfigureItem: Driver<FridgeIngredient>
        let buttonTitle: Driver<String>
        let isButtonEnabled: Driver<Bool>
    }
    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    
    private let selectedItemsRelay = BehaviorRelay<Set<Int>>(value: [])
    
    private var allCategories: [FridgeCategory] = []
    private var allSubcategories: [FridgeSubcategory] = []
    private var allIngredients: [FridgeIngredient] = []
    private var allSections: [IngredientSectionModel] = []
    private var isScrollingProgrammatically = false  // 무한루프 방지
    
    
    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
        loadData()
    }
    
    func transform(input: Input) -> Output {
        let scrollToSectionRelay = PublishRelay<Int>()
        let selectedCategoryIndexRelay = BehaviorRelay<Int>(value: 0)
        let reconfigureItemRelay = PublishRelay<FridgeIngredient>()
        
        // 재료 선택/해제
        input.selectedIngredientIndex
            .withUnretained(self)
            .bind { owner, indexPath in
                guard indexPath.section < self.allSections.count,
                      indexPath.item < self.allSections[indexPath.section].items.count else { return }
                
                let ingredient = self.allSections[indexPath.section].items[indexPath.item]
                var current = owner.selectedItemsRelay.value
                
                if current.contains(ingredient.id) {
                    current.remove(ingredient.id)
                } else {
                    current.insert(ingredient.id)
                }
                
                owner.selectedItemsRelay.accept(current)
                reconfigureItemRelay.accept(ingredient)
            }
            .disposed(by: disposeBag)
        
        // 카테고리 선택 시 해당 섹션으로 스크롤
        input.selectedCategoryIndex
            .withUnretained(self)
            .bind { owner, indexPath in
                guard indexPath.item < owner.allCategories.count else { return }
                
                let categoryId = owner.allCategories[indexPath.item].id
                
                // 해당 카테고리의 첫 번째 섹션 찾기
                if let sectionIndex = owner.allSections.firstIndex(where: {
                    $0.header.categoryId == categoryId
                }) {
                    owner.isScrollingProgrammatically = true
                    scrollToSectionRelay.accept(sectionIndex)
                    selectedCategoryIndexRelay.accept(indexPath.item)
                    
                    // 0.5초 후 플래그 해제
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        owner.isScrollingProgrammatically = false
                    }
                }
            }
            .disposed(by: disposeBag)
        
        // 스크롤로 보이는 섹션이 변경될 때 카테고리 선택
        input.visibleSectionIndex
            .withUnretained(self)
            .bind { owner, sectionIndex in
                guard !self.isScrollingProgrammatically,
                      sectionIndex < owner.allSections.count else { return }
                
                let categoryId = owner.allSections[sectionIndex].header.categoryId
                
                if let categoryIndex = owner.allCategories.firstIndex(where: { $0.id == categoryId }) {
                    selectedCategoryIndexRelay.accept(categoryIndex)
                }
            }
            .disposed(by: disposeBag)
        
        let buttonTitle = selectedItemsRelay
            .map { selectedIds in
                selectedIds.isEmpty ? "재료 추가하기" : "\(selectedIds.count)개의 재료 추가하기"
            }
            .asDriver(onErrorJustReturn: "재료 추가하기")
        
        let isButtonEnabled = selectedItemsRelay
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)
        
        return Output(
            categories: Driver.just(allCategories),
            ingredientSections: Driver.just(allSections),
            scrollToSection: scrollToSectionRelay.asDriver(onErrorJustReturn: 0),
            selectedCategoryIndex: selectedCategoryIndexRelay.asDriver(),
            reconfigureItem: reconfigureItemRelay.asDriver(onErrorDriveWith: .empty()),
            buttonTitle: buttonTitle,
            isButtonEnabled: isButtonEnabled
        )
    }
    
    func getSelectedIngredients() -> [FridgeIngredient] {
        let selectedIds = selectedItemsRelay.value
        return allIngredients.filter { selectedIds.contains($0.id) }
    }
    
    func isIngredientSelected(_ id: Int) -> Bool {
        return selectedItemsRelay.value.contains(id)
    }
}

private extension IngredientSelectionViewModel {
    func loadData() {
        let (categories, subcategories, ingredients) = repository.getFridgeEntities()
        allCategories = categories
        allSubcategories = subcategories
        allIngredients = ingredients
        
        // 서브카테고리별 섹션으로 그룹화
        for category in allCategories {
            let subcategories = allSubcategories.filter { $0.categoryId == category.id }
            
            for subcategory in subcategories {
                let ingredients = allIngredients.filter { $0.subcategoryId == subcategory.id }
                
                if !ingredients.isEmpty {
                    allSections.append(IngredientSectionModel(
                        header: subcategory,
                        items: ingredients
                    ))
                }
            }
        }
    }
}
