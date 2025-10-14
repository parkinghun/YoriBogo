//
//  ImagePickerManager.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-14.
//

import UIKit
import PhotosUI
import AVFoundation

final class ImagePickerManager: NSObject {

    // MARK: - Properties
    private weak var presentingViewController: UIViewController?
    private var completion: (([UIImage]) -> Void)?
    private var maxSelectionCount: Int = 5

    // MARK: - Initialization
    override init() {
        super.init()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// 이미지 선택을 시작합니다 (카메라 또는 앨범 선택 액션시트 표시)
    /// - Parameters:
    ///   - viewController: 현재 뷰컨트롤러
    ///   - maxCount: 최대 선택 가능한 이미지 개수 (기본값 5)
    ///   - completion: 선택 완료 시 호출되는 클로저
    func presentImagePicker(
        from viewController: UIViewController,
        maxSelectionCount maxCount: Int = 5,
        completion: @escaping ([UIImage]) -> Void
    ) {
        self.presentingViewController = viewController
        self.completion = completion
        self.maxSelectionCount = maxCount

        showImageSourceActionSheet()
    }

    // MARK: - Private Methods

    private func showImageSourceActionSheet() {
        guard let viewController = presentingViewController else { return }

        let actionSheet = UIAlertController(
            title: "이미지 추가",
            message: "이미지를 추가할 방법을 선택하세요",
            preferredStyle: .actionSheet
        )

        // 카메라
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }

        // 앨범
        actionSheet.addAction(UIAlertAction(title: "앨범", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        })

        // 취소
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 대응
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true)
    }

    private func presentCamera() {
        checkCameraPermission { [weak self] granted in
            guard granted else { return }
            self?.showCamera()
        }
    }

    private func showCamera() {
        guard let viewController = presentingViewController else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false

        viewController.present(picker, animated: true)
    }

    // MARK: - Camera Permission
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:  // 이미 권한이 부여됨
            completion(true)

        case .notDetermined:  // 권한이 결정되지 않음 → 권한 요청
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(true)
                    } else {
                        self.showPermissionDeniedAlert()
                        completion(false)
                    }
                }
            }

        case .denied, .restricted:
            // 권한이 거부되었거나 제한됨 → 설정으로 이동 안내
            showPermissionDeniedAlert()
            completion(false)

        @unknown default:
            completion(false)
        }
    }

    private func showPermissionDeniedAlert() {
        guard let viewController = presentingViewController else { return }

        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "레시피 사진을 촬영하려면 카메라 접근 권한이 필요합니다.\n설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {  // 설정 url
                UIApplication.shared.open(settingsURL)
            }
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        viewController.present(alert, animated: true)
    }

    // MARK: - Notifications
    private func setupNotifications() {
        // 앱이 포그라운드로 돌아올 때 권한 상태 재확인
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        // 앱이 포그라운드로 돌아왔을 때 필요한 처리
        // 현재는 별도 처리 없이 다음 카메라 요청 시 자동으로 권한 체크됨
    }

    private func presentPhotoLibrary() {
        guard let viewController = presentingViewController else { return }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = maxSelectionCount
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self

        viewController.present(picker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            completion?([image])
        }

        // 메모리 정리
        cleanup()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        cleanup()
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ImagePickerManager: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            cleanup()
            return
        }

        var images: [UIImage] = []
        let group = DispatchGroup()

        for result in results {
            group.enter()

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                defer { group.leave() }

                if let image = object as? UIImage {
                    images.append(image)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.completion?(images)
            self?.cleanup()
        }
    }
}

// MARK: - Cleanup

extension ImagePickerManager {
    private func cleanup() {
        presentingViewController = nil
        completion = nil
    }
}
