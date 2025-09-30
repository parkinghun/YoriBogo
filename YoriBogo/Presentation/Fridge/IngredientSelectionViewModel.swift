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
    struct Input {
//        let selectedCategoryId: Signal<Int?>
//        let visibleSectionChanged: Signal<Int>
        let selectedIngredientIndex: ControlEvent<IndexPath>
    }
    
    
    struct Output {
        let categories: Driver<[FridgeCategory]>
        let ingredientSections: Driver<[IngredientSectionModel]>
        let selectedItemIds: Driver<Set<Int>>  // FridgeIngredient의 id
        let selectedCountText: Driver<String>
    }
    
    // Section = Subcategory
    enum CategorySection: Hashable {
        case main
    }
    typealias CategoryItem = FridgeCategory
    typealias IngredientItem = FridgeIngredient
    
    struct IngredientSectionModel: Hashable {
        let header: FridgeSubcategory
        let items: [IngredientItem]
    }
    
    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    
    
    
    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
    }
    
    func transform(input: Input) -> Output {
        let (categories, subcategories, ingredients) = repository.getFridgeEntities()
        let categoriesDriver = Driver.just(categories)
        
        let allSection: [IngredientSectionModel] = subcategories.map { sub in
            let items = ingredients.filter { $0.subcategoryId == sub.id }
            return IngredientSectionModel(header: sub, items: items)
        }
        let sectionsDriver = Driver.just(allSection)
        
        let selectedRelay = BehaviorRelay<Set<Int>>(value: [])
        input.selectedIngredientIndex
            .share(replay: 1)
            .compactMap { indexPath -> FridgeIngredient? in
                let section = indexPath.section
                let item = indexPath.item
                guard allSection.indices.contains(section) else { return nil }
                let items = allSection[section].items
                guard items.indices.contains(item) else { return nil }
                return items[item]
            }
            .bind { ingredient in
                var selectedIds = selectedRelay.value
                if selectedIds.contains(ingredient.id) {
                    selectedIds.remove(ingredient.id)
                } else {
                    selectedIds.insert(ingredient.id)
                }
                selectedRelay.accept(selectedIds)
            }
            .disposed(by: disposeBag)
        
        let selectedItemIds = selectedRelay.asDriver()
        let selectedCountText = selectedItemIds.map { "\($0.count)개 재료 추가하기" }
        
        return Output(categories: categoriesDriver, ingredientSections: sectionsDriver, selectedItemIds: selectedItemIds, selectedCountText: selectedCountText)
    }
}

struct IngredientItemModel: Hashable {
    let ingredient: FridgeIngredient
    let isSelected: Bool
}
