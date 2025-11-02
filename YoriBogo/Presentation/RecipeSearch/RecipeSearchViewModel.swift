//
//  RecipeSearchViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class RecipeSearchViewModel: ViewModelType {
    struct Input {
        let searchText: Observable<String>
        let searchButtonTapped: Observable<Void>
        let deleteKeyword: Observable<String>
        let clearAllKeywords: Observable<Void>
    }

    struct Output {
        let searchResults: Driver<[(recipe: Recipe, matchRate: Double, matchedIngredients: [String])]>
        let resultCount: Driver<Int>
        let recentSearches: Driver<[String]>
        let isSearching: Driver<Bool>
    }

    private let disposeBag = DisposeBag()
    private let recipeManager = RecipeRealmManager.shared
    private let repository = FridgeIngredientRepository()
    private let recentSearchManager = RecentSearchManager.shared

    init() { }

    func transform(input: Input) -> Output {
        // 검색 버튼 탭 시 검색어 저장
        input.searchButtonTapped
            .withLatestFrom(input.searchText)
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] keyword in
                self?.recentSearchManager.addSearchKeyword(keyword)
            })
            .disposed(by: disposeBag)

        // 검색어 삭제
        input.deleteKeyword
            .subscribe(onNext: { [weak self] keyword in
                self?.recentSearchManager.removeSearchKeyword(keyword)
            })
            .disposed(by: disposeBag)

        // 전체 검색어 삭제
        input.clearAllKeywords
            .subscribe(onNext: { [weak self] in
                self?.recentSearchManager.clearAllSearches()
            })
            .disposed(by: disposeBag)

        // 검색 중 여부 (검색어가 비어있지 않으면 검색 중)
        let isSearching = input.searchText
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)

        // 검색어 디바운스 처리 (0.5초)
        let searchResults = input.searchText
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { [weak self] keyword -> Observable<[(recipe: Recipe, matchRate: Double, matchedIngredients: [String])]> in
                guard let self = self, !keyword.isEmpty else {
                    return Observable.just([])
                }

                // 레시피 검색
                let recipes = self.recipeManager.searchRecipes(keyword: keyword)

                // 보유 재료 조회
                let userIngredients = self.fetchUserIngredients()

                // 각 레시피의 매칭률 계산
                let results: [(recipe: Recipe, matchRate: Double, matchedIngredients: [String])] = recipes.map { recipe in
                    let recipeIngredientNames = recipe.ingredients.map { $0.name.lowercased() }
                    let userIngredientsLower = userIngredients.map { $0.lowercased() }

                    // 매칭되는 재료 찾기 (IngredientMatcher 사용)
                    let matchedIngredients = IngredientMatcher.findMatchedIngredients(
                        recipeIngredients: recipeIngredientNames,
                        userIngredients: userIngredientsLower
                    )

                    // 매칭률 계산 (IngredientMatcher 사용)
                    let matchRate = IngredientMatcher.calculateMatchRate(
                        recipeIngredients: recipeIngredientNames,
                        userIngredients: userIngredientsLower
                    )

                    return (recipe, matchRate, matchedIngredients)
                }

                // 매칭률 높은 순으로 정렬
                let sortedResults = results.sorted { $0.matchRate > $1.matchRate }

                return Observable.just(sortedResults)
            }
            .asDriver(onErrorJustReturn: [])

        let resultCount = searchResults
            .map { $0.count }

        // 최근 검색어 리스트
        let recentSearches = recentSearchManager.recentSearches
            .asDriver(onErrorJustReturn: [])

        return Output(
            searchResults: searchResults,
            resultCount: resultCount,
            recentSearches: recentSearches,
            isSearching: isSearching
        )
    }

    // MARK: - Private Methods
    private func fetchUserIngredients() -> [String] {
        return repository.getIngredientNames()
    }
}
