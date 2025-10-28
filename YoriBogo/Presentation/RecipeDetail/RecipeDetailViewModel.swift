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
    private let matchRate: Double?
    private let matchedIngredients: [String]?
    private let disposeBag = DisposeBag()
    private let recipeManager = RecipeRealmManager.shared
    private let repository = FridgeIngredientRepository()

    // 기존 초기화 (추천 화면에서 사용)
    init(recipe: Recipe, matchRate: Double, matchedIngredients: [String]) {
        self.recipe = recipe
        self.matchRate = matchRate
        self.matchedIngredients = matchedIngredients
    }

    // 편의 초기화 (나의 레시피/북마크 화면에서 사용)
    convenience init(recipe: Recipe) {
        self.init(recipe: recipe, matchRate: 0, matchedIngredients: [])
    }

    func transform(input: Input) -> Output {
        let recipeRelay = BehaviorRelay<Recipe>(value: recipe)
        let isBookmarkedRelay = BehaviorRelay<Bool>(value: recipe.isBookmarked)

        // 북마크 토글
        input.bookmarkButtonTap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                do {
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

        // 매칭 정보 계산 (없으면 자동 계산)
        let calculatedMatchInfo = input.viewDidLoad
            .map { [weak self] _ -> (matchRate: Double, matchedIngredients: [String]) in
                guard let self = self else { return (0, []) }

                // 이미 매칭 정보가 있으면 사용
                if let matchRate = self.matchRate, let matchedIngredients = self.matchedIngredients,
                   matchRate > 0 || !matchedIngredients.isEmpty {
                    return (matchRate, matchedIngredients)
                }

                // 없으면 자동 계산
                return self.calculateMatchInfo()
            }
            .share()

        let matchRateDriver = calculatedMatchInfo
            .map { $0.matchRate }
            .asDriver(onErrorJustReturn: 0)

        let matchedIngredientsDriver = calculatedMatchInfo
            .map { $0.matchedIngredients }
            .asDriver(onErrorJustReturn: [])

        return Output(
            recipe: recipeRelay.asDriver(),
            matchRate: matchRateDriver,
            tags: tags,
            matchedIngredients: matchedIngredientsDriver,
            ingredients: .just(recipe.ingredients),
            steps: .just(recipe.steps),
            tip: .just(recipe.tip),
            isBookmarked: isBookmarkedRelay.asDriver()
        )
    }

    // MARK: - Private Methods

    /// 보유 재료 기반 매칭 정보 계산
    private func calculateMatchInfo() -> (matchRate: Double, matchedIngredients: [String]) {
        // 냉장고 재료 가져오기
        let userIngredients = repository.getIngredientNames()

        guard !userIngredients.isEmpty else {
            return (0, [])
        }

        // 레시피 재료와 매칭
        var matchedIngredients: [String] = []

        for recipeIngredient in recipe.ingredients {
            let recipeIngredientName = recipeIngredient.name.lowercased()

            for userIngredient in userIngredients {
                if IngredientMatcher.isMatch(
                    recipeIngredient: recipeIngredientName,
                    userIngredient: userIngredient.lowercased()
                ) {
                    matchedIngredients.append(userIngredient)
                    break
                }
            }
        }

        // 매칭률 계산
        let totalIngredients = recipe.ingredients.count
        let matchedCount = matchedIngredients.count
        let matchRate = totalIngredients > 0 ? Double(matchedCount) / Double(totalIngredients) : 0

        return (matchRate, matchedIngredients)
    }
}
