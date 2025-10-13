//
//  RecipeViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/13/25.
//

import Foundation
import RxSwift
import RxCocoa

enum RecipeTab: Int {
    case bookmarked = 0
    case myRecipes = 1

    var title: String {
        switch self {
        case .bookmarked: return "북마크"
        case .myRecipes: return "나의 레시피"
        }
    }
}

final class RecipeViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let segmentChanged: Observable<Int>
        let refreshTrigger: Observable<Void>
    }

    struct Output {
        let recipes: Driver<[Recipe]>
        let isEmpty: Driver<Bool>
        let selectedTab: Driver<RecipeTab>
        let emptyMessage: Driver<String>
    }

    private let recipeManager = RecipeRealmManager.shared
    private let disposeBag = DisposeBag()

    init() { }

    func transform(input: Input) -> Output {
        let selectedTabRelay = BehaviorRelay<RecipeTab>(value: .bookmarked)
        let recipesRelay = BehaviorRelay<[Recipe]>(value: [])
        let isEmptyRelay = BehaviorRelay<Bool>(value: true)
        let emptyMessageRelay = BehaviorRelay<String>(value: "북마크한 레시피가 없습니다")

        // 세그먼트 변경
        input.segmentChanged
            .compactMap { RecipeTab(rawValue: $0) }
            .bind(to: selectedTabRelay)
            .disposed(by: disposeBag)

        // 데이터 로드 트리거 (viewDidLoad + segmentChanged + refreshTrigger)
        let loadTrigger = Observable.merge(
            input.viewDidLoad.map { _ in },
            input.segmentChanged.map { _ in },
            input.refreshTrigger
        )

        // 데이터 로드
        Observable.combineLatest(loadTrigger, selectedTabRelay)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, tab in
                guard let self = self else { return }

                let recipes: [Recipe]
                let emptyMessage: String

                switch tab {
                case .bookmarked:
                    recipes = self.recipeManager.fetchBookmarkedRecipes()
                    emptyMessage = "북마크한 레시피가 없습니다"
                case .myRecipes:
                    // TODO: 사용자가 추가한 레시피 가져오기
                    recipes = []
                    emptyMessage = "작성한 레시피가 없습니다"
                }

                recipesRelay.accept(recipes)
                isEmptyRelay.accept(recipes.isEmpty)
                emptyMessageRelay.accept(emptyMessage)
            })
            .disposed(by: disposeBag)

        return Output(
            recipes: recipesRelay.asDriver(),
            isEmpty: isEmptyRelay.asDriver(),
            selectedTab: selectedTabRelay.asDriver(),
            emptyMessage: emptyMessageRelay.asDriver()
        )
    }
}
