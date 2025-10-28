//
//  TimerViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/28/25.
//

import UIKit

final class TimerViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
    }
    
    private func setupNavigation() {
        setNavigationTitle("타이머")
    }
}
