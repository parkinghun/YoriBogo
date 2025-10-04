//
//  UIImageView+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import Kingfisher

extension UIImageView {
    /// Kingfisher를 사용하여 이미지를 로드합니다.
    /// - HTTP URL은 자동으로 HTTPS로 변환됩니다.
    /// - 다운샘플링을 적용하여 메모리 효율적으로 이미지를 로드합니다.
    ///
    /// - Parameters:
    ///   - urlString: 이미지 URL 문자열
    ///   - placeholder: 로딩 중 또는 실패 시 표시할 플레이스홀더 이미지
    ///   - downsamplingSize: 다운샘플링 크기 (기본값: 이미지뷰의 bounds.size)
    func setImageWithKF(
        urlString: String?,
        placeholder: UIImage? = UIImage(systemName: "photo"),
        downsamplingSize: CGSize? = nil
    ) {
        guard let urlString = urlString else {
            self.image = placeholder
            return
        }

        // HTTP -> HTTPS 변환
        let httpsURLString = urlString.replacingOccurrences(of: "http://", with: "https://")

        guard let url = URL(string: httpsURLString) else {
            self.image = placeholder
            return
        }

        // 다운샘플링 크기 결정 (지정되지 않으면 이미지뷰 크기 사용)
        let targetSize = downsamplingSize ?? self.bounds.size

        // 크기가 유효하지 않으면 기본 크기 사용
        let finalSize = (targetSize.width > 0 && targetSize.height > 0)
            ? targetSize
            : CGSize(width: 300, height: 300)

        // Kingfisher 옵션 설정
        let processor = DownsamplingImageProcessor(size: finalSize)
        let options: KingfisherOptionsInfo = [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ]

        // 이미지 로드
        self.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: options
        )
    }
}
