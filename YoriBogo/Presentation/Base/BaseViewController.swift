//
//  BaseViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackgroundColor()
    }
    
    func setBackgroundColor() {
        view.backgroundColor = .white
    }
    
}
