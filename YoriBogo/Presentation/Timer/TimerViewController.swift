//
//  TimerViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/28/25.
//

import UIKit
import SnapKit


final class TimerViewController: BaseViewController {

    private let emptyView = TimerEmptyView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        setupActions()
    }

    private func setupNavigation() {
        setNavigationTitle("타이머")
    }

    private func configureHierachy() {
        view.addSubview(emptyView)
    }

    private func configureLayout() {
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupActions() {
        emptyView.ctaButton?.addTarget(self, action: #selector(presentTimerAddView), for: .touchUpInside)
    }

    @objc private func presentTimerAddView() {
        let vc = TimerAddViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
}


