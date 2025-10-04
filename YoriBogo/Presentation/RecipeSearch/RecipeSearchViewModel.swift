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
    }

    struct Output {
        let searchResults: Driver<[(recipe: Recipe, matchRate: Double, matchedIngredients: [String])]>
        let resultCount: Driver<Int>
    }

    private let disposeBag = DisposeBag()
    private let recipeManager = RecipeRealmManager.shared

    init() { }

    func transform(input: Input) -> Output {
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

                    // 매칭되는 재료 찾기
                    let matchedIngredients = recipeIngredientNames.filter { recipeIngredient in
                        userIngredientsLower.contains { userIngredient in
                            recipeIngredient.contains(userIngredient) || userIngredient.contains(recipeIngredient)
                        }
                    }

                    // 매칭률 계산
                    let matchRate = recipeIngredientNames.isEmpty ? 0.0 : Double(matchedIngredients.count) / Double(recipeIngredientNames.count)

                    return (recipe, matchRate, matchedIngredients)
                }

                // 매칭률 높은 순으로 정렬
                let sortedResults = results.sorted { $0.matchRate > $1.matchRate }

                return Observable.just(sortedResults)
            }
            .asDriver(onErrorJustReturn: [])

        let resultCount = searchResults
            .map { $0.count }

        return Output(
            searchResults: searchResults,
            resultCount: resultCount
        )
    }

    // MARK: - Private Methods
    private func fetchUserIngredients() -> [String] {
        do {
            let realm = try Realm()
            let ingredientObjects = realm.objects(FridgeIngredientObject.self)
            return ingredientObjects.map { $0.name }
        } catch {
            print("❌ Realm 조회 에러: \(error)")
            return []
        }
    }
}
