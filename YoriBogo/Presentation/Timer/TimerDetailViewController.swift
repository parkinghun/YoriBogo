//
//  TimerDetailViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 12/5/25.
//

import UIKit
import SnapKit

/// 타이머 상세 화면
final class TimerDetailViewController: BaseViewController {

    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .brandOrange500
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray800
        label.text = ""
        return label
    }()

    private let circularProgressView = CircularProgressView()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 72, weight: .thin)
        label.textColor = .gray800
        label.text = "0:00"
        label.textAlignment = .center
        return label
    }()

    private let endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray600
        label.text = "🔔 오후 6:05"
        label.textAlignment = .center
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        button.setTitleColor(.gray800, for: .normal)
        button.backgroundColor = .gray200
        button.layer.cornerRadius = 50
        return button
    }()

    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("재개", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 50
        return button
    }()

    private let bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray100
        view.layer.cornerRadius = 16
        return view
    }()

    private let labelTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "레이블"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray600
        return label
    }()

    private let timerNameLabel: UILabel = {
        let label = UILabel()
        label.text = "타이머"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray800
        return label
    }()

    private let endTimeSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "타이머 종료 시"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray600
        return label
    }()

    private let soundLabel: UILabel = {
        let label = UILabel()
        label.text = "전파 탐지기"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray600
        label.textAlignment = .right
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .gray500
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Properties
    var timer: TimerItem

    // MARK: - Initialization
    init(timer: TimerItem) {
        self.timer = timer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateUI()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(circularProgressView)
        view.addSubview(timeLabel)
        view.addSubview(endTimeLabel)
        view.addSubview(cancelButton)
        view.addSubview(playPauseButton)
        view.addSubview(bottomContainerView)

        bottomContainerView.addSubview(labelTitleLabel)
        bottomContainerView.addSubview(timerNameLabel)
        bottomContainerView.addSubview(endTimeSectionLabel)
        bottomContainerView.addSubview(soundLabel)
        bottomContainerView.addSubview(chevronImageView)

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.size.equalTo(44)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(backButton)
        }

        circularProgressView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(60)
            $0.width.height.equalTo(300)
        }

        timeLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(circularProgressView).offset(-10)
        }

        endTimeLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
        }

        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(40)
            $0.top.equalTo(circularProgressView.snp.bottom).offset(60)
            $0.width.height.equalTo(100)
        }

        playPauseButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(40)
            $0.centerY.equalTo(cancelButton)
            $0.width.height.equalTo(100)
        }

        bottomContainerView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(32)
            $0.top.equalTo(cancelButton.snp.bottom).offset(40)
            $0.height.equalTo(120)
        }

        labelTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(20)
        }

        timerNameLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalTo(labelTitleLabel)
        }

        let divider = UIView()
        divider.backgroundColor = .white.withAlphaComponent(0.2)
        bottomContainerView.addSubview(divider)

        divider.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        endTimeSectionLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview().inset(20)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalTo(endTimeSectionLabel)
            $0.size.equalTo(16)
        }

        soundLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalTo(endTimeSectionLabel)
        }
    }

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func cancelButtonTapped() {
        // TODO: 타이머 취소 로직
        print("타이머 취소")
    }

    @objc private func playPauseButtonTapped() {
        // TODO: 재생/일시정지 로직
        timer.isRunning.toggle()
        updatePlayPauseButton()
        print("재생/일시정지")
    }

    // MARK: - Update UI
    private func updateUI() {
        timeLabel.text = timer.remainingTimeString
        timerNameLabel.text = timer.name
        circularProgressView.setProgress(timer.progress, animated: false)
        updateTitleLabel()
        updatePlayPauseButton()
        updateEndTime()
    }

    private func updateTitleLabel() {
        let hours = timer.totalSeconds / 3600
        let minutes = (timer.totalSeconds % 3600) / 60
        let seconds = timer.totalSeconds % 60

        if hours > 0 {
            titleLabel.text = "\(hours)시간 \(minutes)분"
        } else if minutes > 0 {
            if seconds > 0 {
                titleLabel.text = "\(minutes)분 \(seconds)초"
            } else {
                titleLabel.text = "\(minutes)분"
            }
        } else {
            titleLabel.text = "\(seconds)초"
        }
    }

    private func updatePlayPauseButton() {
        if timer.isRunning {
            playPauseButton.setTitle("일시 정지", for: .normal)
            playPauseButton.backgroundColor = .brandOrange500
        } else {
            playPauseButton.setTitle("재개", for: .normal)
            playPauseButton.backgroundColor = .systemGreen
        }
    }

    private func updateEndTime() {
        let endDate = Date().addingTimeInterval(TimeInterval(timer.remainingSeconds))
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        endTimeLabel.text = "🔔 \(formatter.string(from: endDate))"
    }

    /// 외부에서 타이머 업데이트 시 호출
    func updateTimer(_ updatedTimer: TimerItem) {
        self.timer = updatedTimer
        updateUI()
    }
}
