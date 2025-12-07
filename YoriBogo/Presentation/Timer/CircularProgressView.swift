//
//  CircularProgressView.swift
//  YoriBogo
//
//  Created by 박성훈 on 12/5/25.
//

import UIKit

/// 원형 프로그레스 뷰 (타이머 상세 화면용)
final class CircularProgressView: UIView {

    // MARK: - Properties
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let lineWidth: CGFloat = 8.0
    private let trackColor: UIColor = .gray300
    private let progressColor: UIColor = .brandOrange500

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
    }

    // MARK: - Setup
    private func setupLayers() {
        // Track Layer (배경 원)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // Progress Layer (진행 중인 원)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }

    private func updatePath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let startAngle = -CGFloat.pi / 2 // 12시 방향부터 시작
        let endAngle = startAngle + 2 * CGFloat.pi

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }

    // MARK: - Public Methods

    /// 진행률 설정 (0.0 ~ 1.0)
    /// - Parameter progress: 진행률
    /// - Parameter animated: 애니메이션 여부
    func setProgress(_ progress: Double, animated: Bool = false) {
        let clampedProgress = min(max(progress, 0.0), 1.0)

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.add(animation, forKey: "progressAnimation")
        }

        progressLayer.strokeEnd = clampedProgress
    }

    /// 프로그레스 색상 변경
    func setProgressColor(_ color: UIColor) {
        progressLayer.strokeColor = color.cgColor
    }

    /// 트랙 색상 변경
    func setTrackColor(_ color: UIColor) {
        trackLayer.strokeColor = color.cgColor
    }
}
