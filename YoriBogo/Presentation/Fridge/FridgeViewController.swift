//
//  FridgeViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift

final class FridgeViewController: BaseViewController {
    
    private let disposeBag = DisposeBag()
    private var viewModel: FridgeViewModel
    
    init(viewModel: FridgeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func bind() {
        let input = FridgeViewModel.Input()
        let output = viewModel.transform(intput: input)
        
        
    }
    
}
