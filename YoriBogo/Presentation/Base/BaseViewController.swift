//
//  BaseViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

class BaseViewController: UIViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackgroundColor()
    }
    
    func setBackgroundColor() {
        view.backgroundColor = .white
    }
    
}
