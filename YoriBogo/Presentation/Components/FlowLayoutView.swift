//
//  FlowLayoutView.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit

/// 자동으로 줄바꿈되는 Flow Layout View
final class FlowLayoutView: UIView {

    // MARK: - Properties
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    var contentInset: UIEdgeInsets = .zero

    // MARK: - Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }

    override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        return calculateContentSize(for: width)
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return calculateContentSize(for: targetSize.width)
    }

    // MARK: - Public Methods
    func addArrangedSubview(_ view: UIView) {
        addSubview(view)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func removeAllArrangedSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    // MARK: - Private Methods
    private func layoutViews() {
        let availableWidth = bounds.width - contentInset.left - contentInset.right
        var xOffset = contentInset.left
        var yOffset = contentInset.top
        var maxHeightInRow: CGFloat = 0

        subviews.forEach { view in
            let viewSize = view.intrinsicContentSize

            // 현재 줄에 공간이 부족하면 다음 줄로
            if xOffset + viewSize.width > bounds.width - contentInset.right && xOffset > contentInset.left {
                xOffset = contentInset.left
                yOffset += maxHeightInRow + verticalSpacing
                maxHeightInRow = 0
            }

            view.frame = CGRect(
                x: xOffset,
                y: yOffset,
                width: viewSize.width,
                height: viewSize.height
            )

            xOffset += viewSize.width + horizontalSpacing
            maxHeightInRow = max(maxHeightInRow, viewSize.height)
        }

        invalidateIntrinsicContentSize()
    }

    private func calculateContentSize(for width: CGFloat) -> CGSize {
        let availableWidth = width - contentInset.left - contentInset.right
        guard availableWidth > 0 else {
            return CGSize(width: width, height: contentInset.top + contentInset.bottom)
        }

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        subviews.forEach { view in
            let viewSize = view.intrinsicContentSize

            // 현재 줄에 공간이 부족하면 다음 줄로
            if xOffset + viewSize.width > availableWidth && xOffset > 0 {
                xOffset = 0
                yOffset += maxHeightInRow + verticalSpacing
                maxHeightInRow = 0
            }

            xOffset += viewSize.width + horizontalSpacing
            maxHeightInRow = max(maxHeightInRow, viewSize.height)
        }

        let totalHeight = yOffset + maxHeightInRow + contentInset.top + contentInset.bottom
        return CGSize(width: width, height: totalHeight)
    }
}
