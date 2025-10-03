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

struct CategoryChip: Hashable {
    let id: Int  // -1: 전체, 나머지는 categoryId
    let name: String
    let isSelected: Bool
}

final class FridgeViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let addButtonTapped: Observable<Void>
        let categorySelected: Observable<Int>  // 선택된 카테고리 ID
    }

    struct Output {
        let isEmpty: Driver<Bool>
        let sections: Driver<[FridgeCategorySection]>
        let categoryChips: Driver<[CategoryChip]>
        let selectedCategoryIds: Driver<Set<Int>>
        let pushIngredientSelectionVC: Driver<Void>
    }

    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    private let selectedCategoriesRelay = BehaviorRelay<Set<Int>>(value: [-1])  // 초기값: 전체 선택

    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        let isEmptyRelay = BehaviorRelay<Bool>(value: true)
        let sectionsRelay = BehaviorRelay<[FridgeCategorySection]>(value: [])
        let categoryChipsRelay = BehaviorRelay<[CategoryChip]>(value: [])

        // 카테고리 선택 처리
        input.categorySelected
            .withUnretained(self)
            .subscribe(onNext: { owner, selectedId in
                var currentSelection = owner.selectedCategoriesRelay.value
                if selectedId == -1 {
                    currentSelection = [-1]
                } else {
                    currentSelection.remove(-1)

                    if currentSelection.contains(selectedId) {
                        currentSelection.remove(selectedId)

                        if currentSelection.isEmpty {
                            currentSelection = [-1]
                        }
                    } else {
                        currentSelection.insert(selectedId)
                    }
                }

                owner.selectedCategoriesRelay.accept(currentSelection)
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(
            input.viewDidLoad,
            selectedCategoriesRelay.asObservable()
        )
        .withUnretained(self)
        .subscribe(onNext: { owner, data in
            let (_, selectedIds) = data

            let allIngredients = owner.repository.getIngredients()
            isEmptyRelay.accept(allIngredients.isEmpty)

            if allIngredients.isEmpty {
                sectionsRelay.accept([])
                categoryChipsRelay.accept([])
            } else {
                let chips = owner.createCategoryChips(from: allIngredients, selectedIds: selectedIds)
                categoryChipsRelay.accept(chips)

                let ingredients: [FridgeIngredientDetail]  // Realm에서 필터링된 데이터 가져오기

                if selectedIds.contains(-1) {
                    ingredients = allIngredients
                } else {
                    let categoryIds = Array(selectedIds)
                    ingredients = owner.repository.getIngredients(byCategoryIds: categoryIds)
                }

                let sections = owner.groupByCategory(ingredients)
                sectionsRelay.accept(sections)
            }
        })
        .disposed(by: disposeBag)

        let pushIngredientSelectionVC = input.addButtonTapped.asDriver(onErrorJustReturn: ())

        return Output(
            isEmpty: isEmptyRelay.asDriver(),
            sections: sectionsRelay.asDriver(),
            categoryChips: categoryChipsRelay.asDriver(),
            selectedCategoryIds: selectedCategoriesRelay.asDriver(),
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

    func createCategoryChips(from ingredients: [FridgeIngredientDetail], selectedIds: Set<Int>) -> [CategoryChip] {
        var chips = [CategoryChip(id: -1, name: "전체", isSelected: selectedIds.contains(-1))]

        let uniqueCategoryIds = Set(ingredients.map { $0.categoryId })

        let categoryChips = uniqueCategoryIds.sorted().map { categoryId in
            let categoryName = repository.getCategoryName(for: categoryId)
            let isSelected = selectedIds.contains(categoryId)
            return CategoryChip(id: categoryId, name: categoryName, isSelected: isSelected)
        }

        chips.append(contentsOf: categoryChips)
        return chips
    }
}
