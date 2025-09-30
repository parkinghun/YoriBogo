//
//  FridgeViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift
import SnapKit

final class FridgeViewController: BaseViewController, ConfigureViewController {
    
    let emptyView = FridgeEmptyView()
    
    private let disposeBag = DisposeBag()
    private var viewModel: FridgeViewModel
    
    
    init(viewModel: FridgeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = emptyView
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        bind()
    }
    
    func bind() {
        let input = FridgeViewModel.Input(nextButtontapped: emptyView.ctaButton.rx.tap)
        let output = viewModel.transform(input: input)
        
        output.pushIngredientSelelctionVC
            .drive(with: self) { owner, _ in
                let vc  = IngredientSelectionViewController(viewModel: .init())
                vc.hidesBottomBarWhenPushed = true

                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
    }
    
    private func setupNavigation() {
        navigationItem.title = "냉장고"
    }
    
    func configureHierachy() {
//        self.view.addSubview(emptyView)
    }
    
    func configureLayout() {
//        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    
}
