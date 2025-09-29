//
//  ViewModelType.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
