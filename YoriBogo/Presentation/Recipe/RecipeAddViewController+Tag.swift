//
//  RecipeAddViewController+Tag.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-15.
//

import UIKit
import SnapKit

// MARK: - Tag Management
extension RecipeAddViewController {

    // Note: 태그 추가는 ViewModel에서 처리하고, updateTagChips는 Output 바인딩에서 호출됨

    func updateTagChips() {
        tagChipsContainer.subviews.forEach { $0.removeFromSuperview() }

        guard !tags.isEmpty else {
            tagChipsContainer.snp.updateConstraints {
                $0.height.equalTo(0)
            }
            return
        }

        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 8
        containerStack.alignment = .leading
        containerStack.distribution = .fill

        tagChipsContainer.addSubview(containerStack)
        containerStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let availableWidth = UIScreen.main.bounds.width - 40
        let horizontalSpacing: CGFloat = 8
        let chipHeight: CGFloat = 32

        var currentRowStack: UIStackView?
        var currentRowWidth: CGFloat = 0
        var rowCount = 0

        for (index, tag) in tags.enumerated() {
            let chipWidth = calculateChipWidth(for: tag)

            if currentRowStack == nil || (currentRowWidth + chipWidth + horizontalSpacing) > availableWidth {
                let newRowStack = UIStackView()
                newRowStack.axis = .horizontal
                newRowStack.spacing = horizontalSpacing
                newRowStack.alignment = .leading
                newRowStack.distribution = .fill
                containerStack.addArrangedSubview(newRowStack)
                currentRowStack = newRowStack
                currentRowWidth = 0
                rowCount += 1
            }

            let chipView = createTagChip(tag: tag, index: index)
            currentRowStack?.addArrangedSubview(chipView)

            if currentRowWidth > 0 {
                currentRowWidth += horizontalSpacing
            }
            currentRowWidth += chipWidth
        }

        let totalHeight = CGFloat(rowCount) * chipHeight + CGFloat(max(0, rowCount - 1)) * 8
        tagChipsContainer.snp.updateConstraints {
            $0.height.equalTo(totalHeight)
        }
    }

    func calculateChipWidth(for tag: String) -> CGFloat {
        let text = "#\(tag)"
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textWidth = (text as NSString).size(withAttributes: attributes).width

        return textWidth + 12 + 8 + 16 + 8 + 8
    }

    func createTagChip(tag: String, index: Int) -> UIView {
        let chipView = UIView()
        chipView.backgroundColor = .brandOrange50
        chipView.layer.cornerRadius = 16

        let label = UILabel()
        label.text = "#\(tag)"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .brandOrange600

        let deleteButton = UIButton()
        deleteButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        deleteButton.tintColor = .brandOrange500
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(removeTagChip(_:)), for: .touchUpInside)

        chipView.addSubview(label)
        chipView.addSubview(deleteButton)

        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
        }

        deleteButton.snp.makeConstraints {
            $0.leading.equalTo(label.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        chipView.snp.makeConstraints {
            $0.height.equalTo(32)
        }

        return chipView
    }

    @objc func removeTagChip(_ sender: UIButton) {
        let index = sender.tag
        guard index < tags.count else { return }

        // ViewModel에게 삭제 알림 (tagRemovedRelay 사용)
        // tagRemovedRelay는 private이므로 직접 접근 불가
        // 대신 태그를 직접 삭제하고 ViewModel이 업데이트된 tags 배열을 감지하도록 함
        tags.remove(at: index)
        updateTagChips()
    }
}
