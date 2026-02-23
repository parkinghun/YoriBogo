//
//  ImagePathHelper.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-16.
//

import UIKit
import CommonCrypto

/// 이미지 경로 관리 및 파일 무결성을 보장하는 헬퍼 클래스
/// - 상대 경로와 절대 경로 변환
/// - 파일 존재 확인 및 fallback 처리
/// - 앱 재설치 시에도 안전한 경로 관리
final class ImagePathHelper {
    static let shared = ImagePathHelper()

    private let fileManager = FileManager.default
    private let imageDirectoryName = "RecipeImages"

    private init() {
        createImageDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    /// RecipeImages 디렉토리의 절대 경로를 반환
    var imageDirectoryURL: URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents directory not found")
        }
        return documentsURL.appendingPathComponent(imageDirectoryName, isDirectory: true)
    }

    /// RecipeImages 디렉토리가 없으면 생성
    private func createImageDirectoryIfNeeded() {
        let directoryURL = imageDirectoryURL

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    // MARK: - Path Conversion

    /// 상대 경로를 절대 경로로 변환
    /// - Parameter relativePath: 상대 경로 (예: RecipeImages/main_0_UUID.jpg)
    /// - Returns: 절대 경로 (예: /var/.../Documents/RecipeImages/main_0_UUID.jpg)
    func toAbsolutePath(_ relativePath: String) -> String {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return relativePath
        }

        return documentsURL.appendingPathComponent(relativePath).path
    }
    /// 이미지 파일을 로드하고, 없으면 fallback 처리
    /// - Parameters:
    ///   - path: 이미지 경로 (상대 또는 절대)
    ///   - fallbackImage: 파일이 없을 때 반환할 이미지 (기본값: nil)
    /// - Returns: UIImage 또는 nil
    func loadImage(at path: String, fallback fallbackImage: UIImage? = nil) -> UIImage? {
        // 절대 경로로 변환
        let absolutePath = path.hasPrefix("/") ? path : toAbsolutePath(path)

        // 파일 존재 확인
        guard fileManager.fileExists(atPath: absolutePath) else {
            return fallbackImage
        }

        // 이미지 로드
        guard let image = UIImage(contentsOfFile: absolutePath) else {
            return fallbackImage
        }

        return image
    }

    // MARK: - File Saving

    /// 이미지를 로컬에 저장하고 상대 경로 반환
    /// - Parameters:
    ///   - image: 저장할 이미지
    ///   - prefix: 파일명 prefix (예: "main", "step_1")
    ///   - index: 이미지 인덱스
    /// - Returns: 상대 경로 또는 nil
    func saveImage(_ image: UIImage, prefix: String, index: Int) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let fileName = "\(prefix)_\(index)_\(UUID().uuidString).jpg"
        let fileURL = imageDirectoryURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)

            // 상대 경로 반환
            let relativePath = "\(imageDirectoryName)/\(fileName)"
            return relativePath
        } catch {
            return nil
        }
    }

    // MARK: - File Deletion

    /// 이미지 파일 삭제 (상대 또는 절대 경로 지원)
    /// - Parameter path: 삭제할 파일 경로
    /// - Returns: 삭제 성공 여부
    @discardableResult
    func deleteImage(at path: String) -> Bool {
        let absolutePath = path.hasPrefix("/") ? path : toAbsolutePath(path)

        guard fileManager.fileExists(atPath: absolutePath) else {
            return false
        }

        do {
            try fileManager.removeItem(atPath: absolutePath)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Batch Operations

    /// 여러 이미지 파일 삭제
    /// - Parameter paths: 삭제할 파일 경로 배열
    func deleteImages(at paths: [String]) {
        for path in paths {
            deleteImage(at: path)
        }
    }

    /// RecipeImages 디렉토리의 모든 파일 경로를 반환 (상대 경로)
    /// - Returns: 상대 경로 배열
    func allImagePaths() -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(atPath: imageDirectoryURL.path) else {
            return []
        }

        return files.map { "\(imageDirectoryName)/\($0)" }
    }

    // MARK: - Recipe Image Cleanup

    /// 레시피의 모든 이미지 파일 삭제 (메인 이미지 + 단계별 이미지)
    /// - Parameter recipe: 삭제할 레시피
    func deleteAllImagesForRecipe(_ recipe: Recipe) {
        var imagePaths: [String] = []

        // 메인 이미지 경로 수집
        for recipeImage in recipe.images {
            if recipeImage.source == .localPath {
                imagePaths.append(recipeImage.value)
            }
        }

        // 단계별 이미지 경로 수집
        for step in recipe.steps {
            for recipeImage in step.images {
                if recipeImage.source == .localPath {
                    imagePaths.append(recipeImage.value)
                }
            }
        }

        // 수집된 모든 이미지 삭제
        if !imagePaths.isEmpty {
            deleteImages(at: imagePaths)
        }
    }

    // MARK: - Duplicate Detection

    /// 이미지의 SHA-256 해시값 계산
    /// - Parameter image: 해시를 계산할 이미지
    /// - Returns: SHA-256 해시 문자열 또는 nil
    private func calculateImageHash(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// 특정 해시값을 가진 이미지 파일이 이미 존재하는지 확인
    /// - Parameter hash: 확인할 해시값
    /// - Returns: 존재하는 경우 해당 파일의 상대 경로, 없으면 nil
    private func findImageByHash(_ hash: String) -> String? {
        let files = allImagePaths()

        for path in files {
            // 파일명에서 해시값 추출 (형식: prefix_index_hash.jpg)
            let fileName = (path as NSString).lastPathComponent
            let components = fileName.components(separatedBy: "_")

            // 파일명이 최소 3개 부분으로 구성되어 있는지 확인
            guard components.count >= 3 else { continue }

            // UUID 부분 추출 (마지막에서 .jpg 제거)
            let uuidPart = components.dropFirst(2).joined(separator: "_")
            let fileHash = (uuidPart as NSString).deletingPathExtension

            // 해시값이 일치하는지 확인
            if fileHash.hasPrefix(hash.prefix(16)) {
                return path
            }
        }

        return nil
    }

    /// 이미지를 저장하되, 중복이 있으면 기존 경로 반환
    /// - Parameters:
    ///   - image: 저장할 이미지
    ///   - prefix: 파일명 prefix
    ///   - index: 이미지 인덱스
    /// - Returns: 상대 경로 (새로 저장하거나 기존 경로)
    func saveImageWithDuplicateCheck(_ image: UIImage, prefix: String, index: Int) -> String? {
        // 이미지 해시 계산
        guard let hash = calculateImageHash(image) else {
            return saveImage(image, prefix: prefix, index: index)
        }

        // 중복 확인
        if let existingPath = findImageByHash(hash) {
            return existingPath
        }

        // 중복이 없으면 새로 저장 (해시를 파일명에 포함)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        // 해시의 앞 16자를 파일명에 포함
        let hashPrefix = String(hash.prefix(16))
        let fileName = "\(prefix)_\(index)_\(hashPrefix)_\(UUID().uuidString).jpg"
        let fileURL = imageDirectoryURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)

            let relativePath = "\(imageDirectoryName)/\(fileName)"
            return relativePath
        } catch {
            return nil
        }
    }
}
