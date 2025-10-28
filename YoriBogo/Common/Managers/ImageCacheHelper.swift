//
//  ImageCacheHelper.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-16.
//

import UIKit

/// 메모리에 임시로 추가된 이미지를 관리하는 헬퍼 클래스
/// - 사용자가 이미지 피커에서 선택한 이미지를 임시로 저장
/// - 저장 전까지는 메모리 캐시로 관리
/// - 실제 저장 시에만 파일 시스템에 저장
final class ImageCacheHelper {
    static let shared = ImageCacheHelper()

    // MARK: - Properties

    /// 임시 이미지 캐시 (UUID: UIImage)
    private var tempImageCache: [String: UIImage] = [:]

    /// 캐시 키 prefix
    private let tempKeyPrefix = "temp_"

    private init() {}

    // MARK: - Temp Image Management

    /// 임시 이미지를 캐시에 저장하고 임시 경로 반환
    /// - Parameter image: 저장할 이미지
    /// - Returns: 임시 경로 (예: "temp_UUID")
    func cacheTempImage(_ image: UIImage) -> String {
        let tempKey = "\(tempKeyPrefix)\(UUID().uuidString)"
        tempImageCache[tempKey] = image
        return tempKey
    }

    /// 임시 경로에서 이미지 로드
    /// - Parameter path: 임시 경로
    /// - Returns: 캐시된 이미지 또는 nil
    func loadTempImage(at path: String) -> UIImage? {
        return tempImageCache[path]
    }

    /// 임시 경로인지 확인
    /// - Parameter path: 확인할 경로
    /// - Returns: 임시 경로 여부
    func isTempPath(_ path: String) -> Bool {
        return path.hasPrefix(tempKeyPrefix)
    }

    /// 임시 이미지 삭제
    /// - Parameter path: 삭제할 임시 경로
    func removeTempImage(at path: String) {
        tempImageCache.removeValue(forKey: path)
    }

    /// 모든 임시 이미지 삭제
    func clearAllTempImages() {
        tempImageCache.removeAll()
        print("✅ 모든 임시 이미지 캐시 삭제")
    }

    /// 특정 prefix를 가진 임시 이미지들 삭제
    /// - Parameter prefix: 삭제할 prefix (예: "main", "step_1")
    func clearTempImages(withPrefix prefix: String) {
        let keysToRemove = tempImageCache.keys.filter { key in
            // temp_prefix_UUID 형태에서 prefix 추출
            let components = key.components(separatedBy: "_")
            return components.count >= 3 && components[1] == prefix
        }

        keysToRemove.forEach { tempImageCache.removeValue(forKey: $0) }
        print("✅ \(prefix) 임시 이미지 \(keysToRemove.count)개 삭제")
    }

    // MARK: - Image Loading (Unified)

    /// 경로에서 이미지 로드 (임시 경로, 상대 경로, 절대 경로 모두 지원)
    /// - Parameters:
    ///   - path: 이미지 경로
    ///   - fallback: 로드 실패 시 반환할 이미지
    /// - Returns: UIImage 또는 fallback
    func loadImage(at path: String, fallback: UIImage? = nil) -> UIImage? {
        // 1. 임시 경로인 경우
        if isTempPath(path) {
            return loadTempImage(at: path) ?? fallback
        }

        // 2. 로컬 파일 경로인 경우
        return ImagePathHelper.shared.loadImage(at: path, fallback: fallback)
    }

    // MARK: - Statistics

    /// 현재 캐시된 임시 이미지 개수
    var tempImageCount: Int {
        return tempImageCache.count
    }

    /// 현재 캐시 상태 출력
    func printCacheStatus() {
        print("📊 ImageCache 상태: \(tempImageCount)개 이미지")
    }
}
