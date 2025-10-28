//
//  UIViewController+Alert.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-09.
//

import UIKit

extension UIViewController {
    /// 에러를 Alert로 표시
    func showErrorAlert(
        title: String = "오류",
        message: String,
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    /// Error 객체를 Alert로 표시
    func showErrorAlert(
        title: String = "오류",
        error: Error,
        completion: (() -> Void)? = nil
    ) {
        showErrorAlert(
            title: title,
            message: error.localizedDescription,
            completion: completion
        )
    }

    /// 확인/취소 Alert 표시
    func showConfirmAlert(
        title: String,
        message: String,
        confirmTitle: String = "확인",
        cancelTitle: String = "취소",
        confirmHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirmHandler()
        })
        present(alert, animated: true)
    }

    /// 일반 정보 Alert 표시
    func showAlert(
        title: String,
        message: String,
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
