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
        label.font = .systemFont(ofSize: 56, weight: .thin)
        label.textColor = .white
        label.text = "0:00"
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        label.text = "타이머"
        return label
    }()

    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
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
        view.layer.borderWidth = 2.5
        view.layer.cornerRadius = 40
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

        timeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(32)
            $0.centerY.equalToSuperview().offset(-10)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(timeLabel)
            $0.top.equalTo(timeLabel.snp.bottom).offset(4)
        }

        circleView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(32)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(80)
        }

        playPauseButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(40)
        }

        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
    }

    @objc private func playPauseButtonTapped() {
        onPlayPauseTapped?()
    }

    // MARK: - Configuration
    func configure(with timer: TimerItem) {
        timeLabel.text = timer.remainingTimeString
        nameLabel.text = timer.name

        // 재생/일시정지 버튼 아이콘 변경
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let iconName = timer.isRunning ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: iconName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
    }
}
