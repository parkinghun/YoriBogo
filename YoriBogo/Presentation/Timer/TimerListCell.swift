//
//  TimerListCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 12/5/25.
//

import UIKit
import SnapKit

/// 타이머 목록 셀
final class TimerListCell: UITableViewCell {

    static let identifier = "TimerListCell"

    // MARK: - UI Components
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 44, weight: .thin)
        label.textColor = .gray800
        label.text = "0:00"
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray600
        label.text = "타이머"
        return label
    }()

    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: "play.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .brandOrange500
        button.backgroundColor = .clear
        return button
    }()

    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.brandOrange500.cgColor
        view.layer.borderWidth = 2.0
        view.layer.cornerRadius = 30
        return view
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray300
        return view
    }()

    // MARK: - Properties
    var onPlayPauseTapped: (() -> Void)?

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(timeLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(circleView)
        circleView.addSubview(playPauseButton)
        contentView.addSubview(dividerView)

        timeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.centerY.equalToSuperview().offset(-8)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(timeLabel)
            $0.top.equalTo(timeLabel.snp.bottom).offset(2)
        }

        circleView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(60)
        }

        playPauseButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(32)
        }

        dividerView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
    }

    @objc private func playPauseButtonTapped() {
        onPlayPauseTapped?()
    }

    // MARK: - Configuration
    func configure(with timer: TimerItem) {
        // 시간 레이블 업데이트 (깜빡임 없이)
        if timeLabel.text != timer.remainingTimeString {
            timeLabel.text = timer.remainingTimeString
        }

        // 이름은 변경되지 않으므로 조건부 업데이트
        if nameLabel.text != timer.name {
            nameLabel.text = timer.name
        }

        // 재생/일시정지 버튼 아이콘 변경
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconName: String
        let isEnabled: Bool

        if timer.isFinished {
            iconName = "arrow.clockwise" // 재시작 아이콘
            isEnabled = true
        } else if timer.isRunning {
            iconName = "pause.fill"
            isEnabled = true
        } else {
            iconName = "play.fill"
            isEnabled = true
        }

        let newImage = UIImage(systemName: iconName, withConfiguration: config)

        // 아이콘이 변경된 경우만 업데이트
        if playPauseButton.currentImage != newImage {
            playPauseButton.setImage(newImage, for: .normal)
            playPauseButton.isEnabled = isEnabled
            playPauseButton.alpha = isEnabled ? 1.0 : 0.5
        }
    }
}
