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
        let nextButtontapped: ControlEvent<Void>
    }
    
    struct Output {
        // repository에서 찾아서
        var showEmptyView: Driver<Bool>
        var pushIngredientSelelctionVC: Driver<Void>
    }
    
    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    
    init(repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
    }
    
    func transform(input: Input) -> Output {
        let showEmptyView = PublishRelay<Bool>()
        repository.getIngredients().isEmpty ? showEmptyView.accept(true) : showEmptyView.accept(false)
        
        let pushIngredientSelelctionVC = input.nextButtontapped.asDriver()
        
        
        return Output(showEmptyView: showEmptyView.asDriver(onErrorJustReturn: true), pushIngredientSelelctionVC: pushIngredientSelelctionVC)
    }
}
