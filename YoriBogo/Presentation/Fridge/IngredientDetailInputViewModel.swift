//
//  IngredientDetailInputViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import Foundation
import RxSwift
import RxCocoa

final class IngredientDetailInputViewModel: ViewModelType {
    struct Input {
        let quantityChanged: Observable<(index: Int, quantity: String)>
        let unitSelected: Observable<(index: Int, unit: String)>
        let dateSelected: Observable<(index: Int, date: Date?)>
        let saveButtonTapped: Observable<Void>
    }
    
    struct Output {
        let ingredients: Driver<[FridgeIngredientDetail]>
        let reloadItemAtIndex: Driver<Int>
        let saveResult: Driver<Result<Void, Error>>
        let dismissScreen: Driver<Void>
    }
    
    private let disposeBag = DisposeBag()
    private let repository: FridgeIngredientRepository
    private var ingredients: [FridgeIngredientDetail]
    
    init(ingredients: [FridgeIngredient],
         repository: FridgeIngredientRepository = FridgeIngredientRepository()) {
        self.repository = repository
        self.ingredients = ingredients.map { FridgeIngredientDetail(from: $0) }
    }
    
    func transform(input: Input) -> Output {
        let saveResultRelay = PublishRelay<Result<Void, Error>>()
        let dismissRelay = PublishRelay<Void>()
        let reloadIndexRelay = PublishRelay<Int>()
        
        // 수량 변경
        input.quantityChanged
            .withUnretained(self)
            .bind { owner, data in
                guard data.index < owner.ingredients.count else { return }
                
                owner.ingredients[data.index].qty = data.quantity.isEmpty ? nil : Double(data.quantity)
                reloadIndexRelay.accept(data.index)
            }
            .disposed(by: disposeBag)
        
        // 단위 선택
        input.unitSelected
            .withUnretained(self)
            .bind { owner, data in
                guard data.index < owner.ingredients.count else { return }
                
                owner.ingredients[data.index].unit = data.unit
                reloadIndexRelay.accept(data.index)
            }
            .disposed(by: disposeBag)
        
        // 날짜 선택
        input.dateSelected
            .withUnretained(self)
            .bind { owner, data in
                guard data.index < owner.ingredients.count else { return }
                
                owner.ingredients[data.index].expirationDate = data.date
                reloadIndexRelay.accept(data.index)
            }
            .disposed(by: disposeBag)
        
        // 저장 처리
        input.saveButtonTapped
            .withUnretained(self)
            .bind { owner, inputData in
                do {
                    for detail in owner.ingredients {
                        let saveModel = detail.toSaveModel()
                        try owner.repository.addIngredient(saveModel)
                    }
                    
                    saveResultRelay.accept(.success(()))
                    dismissRelay.accept(())
                    
                } catch {
                    saveResultRelay.accept(.failure(error))
                }
            }
            .disposed(by: disposeBag)
        
        return Output(ingredients: Driver.just(ingredients),
                      reloadItemAtIndex: reloadIndexRelay.asDriver(onErrorDriveWith: .empty()),
                      saveResult: saveResultRelay.asDriver(onErrorDriveWith: .empty()),
                      dismissScreen: dismissRelay.asDriver(onErrorDriveWith: .empty()))
    }
    
}
