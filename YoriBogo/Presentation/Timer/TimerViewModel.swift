//
//  TimerViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import Foundation
import RxSwift
import RxCocoa

final class TimerViewModel: ViewModelType {
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    private let disposeBag = DisposeBag()
    
    init() { }
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
