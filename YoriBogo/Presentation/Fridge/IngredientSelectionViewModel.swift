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
//        let toggleItem: Signal<IngredientItem>
        
    }
    
    
    struct Output {
        let categories: Driver<[FridgeCategory]>
        let ingredientSections: Driver<[IngredientSectionModel]>
//        let scrollToSectionIndex: Signal<Int> // 카테고리 선택 시 → 해당 카테고리의 첫 섹션 인덱스로 스크롤
//        let highlightCategoryId: Signal<Int>  // 재료 스크롤 시 → 현재 보이는 섹션의 카테고리 id 하이라이트
//        let selectedItemIds: Driver<Set<Int>>
//        let selectedCountText: Driver<String>
        
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
        
        return Output(categories: categoriesDriver, ingredientSections: sectionsDriver)
    }
}
