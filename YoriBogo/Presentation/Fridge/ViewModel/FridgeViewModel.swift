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
        let categorySelected: Observable<Int>
        let sortButtonTapped: Observable<Void>
    }

    struct Output {
        let isEmpty: Driver<Bool>
        let sections: Driver<[FridgeCategorySection]>
        let categoryChips: Driver<[CategoryChip]>
        let selectedCategoryIds: Driver<Set<Int>>
        let totalItemCount: Driver<Int>
        let currentSort: Driver<SortOption>
        let pushIngredientSelectionVC: Driver<Void>
    }

    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    private let selectedCategoriesRelay = BehaviorRelay<Set<Int>>(value: [-1])
    private let currentSortRelay = BehaviorRelay<SortOption>(value: .basic)

    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
    }

    func transform(input: Input) -> Output {
        let isEmptyRelay = BehaviorRelay<Bool>(value: true)
        let sectionsRelay = BehaviorRelay<[FridgeCategorySection]>(value: [])
        let categoryChipsRelay = BehaviorRelay<[CategoryChip]>(value: [])
        let totalItemCountRelay = BehaviorRelay<Int>(value: 0)

        // 정렬 버튼 처리 - 토글
        input.sortButtonTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let current = owner.currentSortRelay.value
                let next: SortOption = current == .basic ? .expiryDate : .basic
                owner.currentSortRelay.accept(next)
            })
            .disposed(by: disposeBag)

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

        // 데이터 로드 (viewDidLoad + 카테고리 선택 + 정렬 변경)
        Observable.combineLatest(
            input.viewDidLoad,
            selectedCategoriesRelay.asObservable(),
            currentSortRelay.asObservable()
        )
        .withUnretained(self)
        .subscribe(onNext: { owner, data in
            let (_, selectedIds, sortOption) = data

            // 전체 재료 가져오기 (정렬 적용)
            let allIngredients = owner.repository.getIngredients(sortBy: sortOption)
            isEmptyRelay.accept(allIngredients.isEmpty)
            totalItemCountRelay.accept(allIngredients.count)

            if allIngredients.isEmpty {
                sectionsRelay.accept([])
                categoryChipsRelay.accept([])
            } else {
                // 카테고리 칩 생성
                let chips = owner.createCategoryChips(from: allIngredients, selectedIds: selectedIds)
                categoryChipsRelay.accept(chips)

                // Realm에서 필터링된 데이터 가져오기 (정렬 적용)
                let ingredients: [FridgeIngredientDetail]

                if selectedIds.contains(-1) {
                    ingredients = allIngredients
                } else {
                    let categoryIds = Array(selectedIds)
                    ingredients = owner.repository.getIngredients(byCategoryIds: categoryIds, sortBy: sortOption)
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
            totalItemCount: totalItemCountRelay.asDriver(),
            currentSort: currentSortRelay.asDriver(),
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

enum Sort: String {
    case basic = "기본순"
    case expiryDate = "소비기한 임박순"
}
