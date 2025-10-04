//
//  RecipeDetailViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import RxSwift
import RxCocoa

final class RecipeDetailViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let bookmarkButtonTap: Observable<Void>
    }

    struct Output {
        let recipe: Driver<Recipe>
        let matchRate: Driver<Double>
        let tags: Driver<[String]>
        let matchedIngredients: Driver<[String]>
        let ingredients: Driver<[RecipeIngredient]>
        let steps: Driver<[RecipeStep]>
        let tip: Driver<String?>
        let isBookmarked: Driver<Bool>
    }

    private let recipe: Recipe
    private let matchRate: Double
    private let matchedIngredients: [String]
    private let disposeBag = DisposeBag()
    private let recipeManager = RecipeRealmManager.shared

    init(recipe: Recipe, matchRate: Double, matchedIngredients: [String]) {
        self.recipe = recipe
        self.matchRate = matchRate
        self.matchedIngredients = matchedIngredients
    }

    func transform(input: Input) -> Output {
        let recipeRelay = BehaviorRelay<Recipe>(value: recipe)
        let isBookmarkedRelay = BehaviorRelay<Bool>(value: recipe.isBookmarked)

        // 북마크 토글
        input.bookmarkButtonTap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                do {
                    print("북마크 버튼 tapped")
                    try self.recipeManager.toggleBookmark(recipeId: self.recipe.id)
                    isBookmarkedRelay.accept(!isBookmarkedRelay.value)
                } catch {
                    print("❌ 북마크 토글 에러: \(error)")
                }
            })
            .disposed(by: disposeBag)

        // 태그 생성
        let tags = input.viewDidLoad
            .map { [weak self] _ -> [String] in
                guard let self = self else { return [] }
                var tagList: [String] = []
                if let method = self.recipe.method {
                    tagList.append(method.displayName)
                }
                if let category = self.recipe.category {
                    tagList.append(category.displayName)
                }
                return tagList
            }
            .asDriver(onErrorJustReturn: [])

        return Output(
            recipe: recipeRelay.asDriver(),
            matchRate: .just(matchRate),
            tags: tags,
            matchedIngredients: .just(matchedIngredients),
            ingredients: .just(recipe.ingredients),
            steps: .just(recipe.steps),
            tip: .just(recipe.tip),
            isBookmarked: isBookmarkedRelay.asDriver()
        )
    }
}
