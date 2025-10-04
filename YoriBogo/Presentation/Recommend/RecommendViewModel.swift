//
//  RecommendViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import Foundation
import RxSwift
import RxCocoa

final class RecommendViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
        let recommendedRecipes: Driver<[Recipe]>
        let hasIngredients: Driver<Bool>
    }

    private let disposeBag = DisposeBag()

    init() { }

    func transform(input: Input) -> Output {
        // TODO: 실제 로직 구현 시 냉장고 재료 확인 및 추천 알고리즘 적용
        let hasIngredients = BehaviorRelay<Bool>(value: true) // 임시로 true

        let recommendedRecipes = input.viewDidLoad
            .flatMapLatest { _ -> Observable<[Recipe]> in
                // TODO: 실제로는 RecipeRealmManager에서 가져오기
                // 임시 더미 데이터 5개 생성
                let dummyRecipes = self.createDummyRecipes()
                return Observable.just(dummyRecipes)
            }
            .asDriver(onErrorJustReturn: [])

        return Output(
            recommendedRecipes: recommendedRecipes,
            hasIngredients: hasIngredients.asDriver()
        )
    }

    // MARK: - Dummy Data (임시)
    private func createDummyRecipes() -> [Recipe] {
        return (0..<5).map { index in
            Recipe(
                id: "dummy-\(index)",
                baseId: "base-\(index)",
                kind: .api,
                version: 0,
                title: "추천 레시피 \(index + 1)",
                category: .sideDish,
                method: .stirFry,
                tags: ["간단", "맛있는"],
                tip: nil,
                images: [
                    RecipeImage(
                        source: .remoteURL,
                        value: "https://via.placeholder.com/400x300",
                        isThumbnail: true
                    )
                ],
                nutrition: nil,
                ingredients: [],
                steps: [],
                isBookmarked: false,
                rating: nil,
                cookCount: 0,
                lastCookedAt: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        }
    }
}
