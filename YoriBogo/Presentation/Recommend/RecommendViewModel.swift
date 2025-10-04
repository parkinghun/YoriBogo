//
//  RecommendViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class RecommendViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let searchButtonTapped: ControlEvent<Void>
    }

    struct Output {
        let recommendedRecipes: Driver<[(recipe: Recipe, matchRate: Double, matchedIngredients: [String])]>
        let hasIngredients: Driver<Bool>
        let pushSearchViewController: Driver<Void>
    }

    private let disposeBag = DisposeBag()
    private let recipeManager = RecipeRealmManager.shared

    init() { }

    func transform(input: Input) -> Output {
        let hasIngredients = BehaviorRelay<Bool>(value: false)

        let recommendedRecipes = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[(recipe: Recipe, matchRate: Double, matchedIngredients: [String])]> in
                guard let self = self else { return Observable.just([]) }

                // Realm에서 보유 재료 조회
                let userIngredients = self.fetchUserIngredients()
                hasIngredients.accept(!userIngredients.isEmpty)

                // 보유 재료 기반 추천 레시피 가져오기
                let recommendations = self.recipeManager.fetchRecommendedRecipes(
                    userIngredients: userIngredients,
                    maxCount: 5
                )

                return Observable.just(recommendations)
            }
            .asDriver(onErrorJustReturn: [])

        let pushSearchViewController = input.searchButtonTapped.asDriver(onErrorJustReturn: ())
        
        return Output(
            recommendedRecipes: recommendedRecipes,
            hasIngredients: hasIngredients.asDriver(),
            pushSearchViewController: pushSearchViewController
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
