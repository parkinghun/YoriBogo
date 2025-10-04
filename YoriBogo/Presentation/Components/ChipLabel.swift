//
//  ChipLabel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit

final class ChipLabel: UILabel {

    enum Style {
        case orangeFill        // 배경 오렌지, 텍스트 진한 오렌지
        case orangeLight       // 배경 연한 오렌지, 텍스트 오렌지
        case greenLight        // 배경 연한 녹색, 텍스트 녹색 (border 있음)
        case custom(textColor: UIColor, backgroundColor: UIColor, borderColor: UIColor? = nil)

        var textColor: UIColor {
            switch self {
            case .orangeFill:
                return .brandOrange600
            case .orangeLight:
                return .systemOrange
            case .greenLight:
                return UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1.0)
            case .custom(let textColor, _, _):
                return textColor
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .orangeFill:
                return .brandOrange100
            case .orangeLight:
                return UIColor.systemOrange.withAlphaComponent(0.1)
            case .greenLight:
                return UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 0.25)
            case .custom(_, let backgroundColor, _):
                return backgroundColor
            }
        }

        var borderColor: UIColor? {
            switch self {
            case .greenLight:
                return UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 0.2)
            case .custom(_, _, let borderColor):
                return borderColor
            default:
                return nil
            }
        }
    }

    enum Size {
        case small      // height: 24, cornerRadius: 12
        case medium     // height: 28, cornerRadius: 14
        case regular    // height: 32, cornerRadius: 16

        var height: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 28
            case .regular: return 32
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .regular: return 16
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 13
            case .regular: return 14
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .regular: return 16
            }
        }
    }

    // MARK: - Properties
    private let chipSize: Size
    private let chipStyle: Style

    // MARK: - Initialization
    init(text: String = "", style: Style = .orangeLight, size: Size = .regular) {
        self.chipSize = size
        self.chipStyle = style
        super.init(frame: .zero)
        setupUI(text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI(text: String) {
        self.text = text
        self.font = .systemFont(ofSize: chipSize.fontSize, weight: .medium)
        self.textColor = chipStyle.textColor
        self.backgroundColor = chipStyle.backgroundColor
        self.textAlignment = .center
        self.layer.cornerRadius = chipSize.cornerRadius
        self.clipsToBounds = true

        // Border 설정
        if let borderColor = chipStyle.borderColor {
            self.layer.borderColor = borderColor.cgColor
            self.layer.borderWidth = 1
        }
    }

    // MARK: - Public Methods
    func updateText(_ text: String) {
        self.text = text
        invalidateIntrinsicContentSize()
    }

    // MARK: - Override for padding
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + (chipSize.horizontalPadding * 2),
            height: chipSize.height
        )
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(
            top: 0,
            left: chipSize.horizontalPadding,
            bottom: 0,
            right: chipSize.horizontalPadding
        )
        super.drawText(in: rect.inset(by: insets))
    }
}
