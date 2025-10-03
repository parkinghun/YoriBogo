//
//  FridgeViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa

struct FridgeCategorySection: Hashable {
    let categoryId: Int
    let categoryName: String
    let items: [FridgeIngredientDetail]
    
    var count: Int {
        return items.count
    }
}

final class FridgeViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let addButtonTapped: ControlEvent<Void>
    }
    
    struct Output {
        let isEmpty: Driver<Bool>
        let sections: Driver<[FridgeCategorySection]>
        let pushIngredientSelectionVC: Driver<Void>
    }
    
    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    
    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
    }
    
    func transform(input: Input) -> Output {
        let isEmptyRelay = BehaviorRelay<Bool>(value: true)
        let sectionsRelay = BehaviorRelay<[FridgeCategorySection]>(value: [])
        
        input.viewDidLoad
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let ingredients = owner.repository.getIngredients()
                
                if ingredients.isEmpty {
                    isEmptyRelay.accept(true)
                    sectionsRelay.accept([])
                } else {
                    isEmptyRelay.accept(false)
                    let sections = owner.groupByCategory(ingredients)
                    sectionsRelay.accept(sections)
                }
            })
            .disposed(by: disposeBag)
        
        let pushIngredientSelectionVC = input.addButtonTapped.asDriver()
        
        return Output(
            isEmpty: isEmptyRelay.asDriver(),
            sections: sectionsRelay.asDriver(),
            pushIngredientSelectionVC: pushIngredientSelectionVC
        )
    }
}

private extension FridgeViewModel {
    func groupByCategory(_ ingredients: [FridgeIngredientDetail]) -> [FridgeCategorySection] {
        let grouped = Dictionary(grouping: ingredients, by: { $0.categoryId })
        
        return grouped.map { categoryId, items in
            let categoryName = repository.getCategoryName(for: categoryId)
            return FridgeCategorySection(
                categoryId: categoryId,
                categoryName: categoryName,
                items: items
            )
        }
        .sorted { $0.categoryId < $1.categoryId }
    }
}
