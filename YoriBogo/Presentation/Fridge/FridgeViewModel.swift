//
//  FridgeViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa

final class FridgeViewModel: ViewModelType {
    struct Input {
        
    }
    
    struct Output {
        // repository에서 찾아서
        var showEmptyView: Driver<Bool>
    }
    
    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    
    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
    }
    
    func transform(intput: Input) -> Output {
        let showEmptyView = PublishRelay<Bool>()
        repository.getIngredients().isEmpty ? showEmptyView.accept(true) : showEmptyView.accept(false)
        
        return Output(showEmptyView: showEmptyView.asDriver(onErrorJustReturn: true))
    }
}
