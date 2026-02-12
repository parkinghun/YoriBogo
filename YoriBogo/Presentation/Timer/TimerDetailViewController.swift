//
//  TimerDetailViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 12/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// 타이머 상세 화면
final class TimerDetailViewController: BaseViewController {

    // MARK: - UI Components
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
        label.text = ""
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

    private let soundSelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
    }()

    // MARK: - Properties
    private let timerManager = TimerManager.shared
    private let disposeBag = DisposeBag()
    private var timer: TimerItem
    private let timerID: UUID

    // MARK: - Initialization
    init(timer: TimerItem) {
        self.timer = timer
        self.timerID = timer.id
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupActions()
        bind()
        updateUI()
    }

    // MARK: - Setup Navigation
    private func setupNavigation() {
        // 네비게이션 타이틀은 updateUI에서 설정
        navigationController?.navigationBar.tintColor = .brandOrange500

        let editButton = UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(editButtonTapped))
        editButton.tintColor = .brandOrange500
        navigationItem.rightBarButtonItem = editButton
    }

    private func bind() {
        // TimerManager의 타이머 리스트 구독하여 현재 타이머 업데이트
        timerManager.timers
            .drive(with: self) { owner, timers in
                if let updatedTimer = timers.first(where: { $0.id == owner.timerID }) {
                    owner.timer = updatedTimer
                    owner.updateUI()
                } else {
                    // 타이머가 삭제된 경우
                    owner.navigationController?.popViewController(animated: true)
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Setup
    private func setupUI() {
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
        bottomContainerView.addSubview(soundSelectButton)

        circularProgressView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
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
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(20)
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

        soundSelectButton.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(divider.snp.bottom)
        }
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        soundSelectButton.addTarget(self, action: #selector(soundSelectButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        let alert = UIAlertController(
            title: "타이머 취소",
            message: "'\(timer.name)' 타이머를 취소하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.timerManager.cancelTimer(id: self.timerID)
        })

        present(alert, animated: true)
    }

    @objc private func playPauseButtonTapped() {
        if timer.isFinished {
            // 완료된 타이머 재시작
            timerManager.restartTimer(id: timerID)
        } else if timer.isRunning {
            timerManager.pauseTimer(id: timerID)
        } else {
            timerManager.startTimer(id: timerID)
        }
    }

    @objc private func editButtonTapped() {
        let editVC = TimerEditViewController()
        editVC.modalPresentationStyle = .overFullScreen
        editVC.modalTransitionStyle = .crossDissolve
        editVC.initialName = timer.name
        editVC.initialSeconds = timer.totalSeconds
        editVC.onSave = { [weak self] name, totalSeconds in
            guard let self = self else { return }
            self.timerManager.updateTimer(id: self.timerID, name: name, duration: TimeInterval(totalSeconds))
        }
        present(editVC, animated: true)
    }

    // MARK: - Update UI
    private func updateUI() {
        timeLabel.text = timer.remainingTimeString
        timerNameLabel.text = timer.name
        circularProgressView.setProgress(timer.progress, animated: true)
        updateNavigationTitle()
        updatePlayPauseButton()
        updateEndTime()
        updateSoundLabel()
    }

    private func updateNavigationTitle() {
        setNavigationTitle(timer.name)
    }

    private func updatePlayPauseButton() {
        if timer.isFinished {
            playPauseButton.setTitle("다시 시작", for: .normal)
            playPauseButton.backgroundColor = .systemGreen
            cancelButton.isEnabled = true
        } else if timer.isRunning {
            playPauseButton.setTitle("일시 정지", for: .normal)
            playPauseButton.backgroundColor = .brandOrange500
            cancelButton.isEnabled = true
        } else {
            playPauseButton.setTitle("재개", for: .normal)
            playPauseButton.backgroundColor = .systemGreen
            cancelButton.isEnabled = true
        }
    }

    private func updateEndTime() {
        if timer.isRunning,
           let endDate = timer.endDate {
            endTimeLabel.text = "\(DateFormatter.timerEndTime.string(from: endDate))"
        } else {
            endTimeLabel.text = ""
        }
    }

    private func updateSoundLabel() {
        soundLabel.text = timer.soundTitle
    }

    @objc private func soundSelectButtonTapped() {
        let currentOption = TimerSettings.option(for: timer.soundID)
        let vc = TimerSoundSettingViewController(mode: .perTimer(current: currentOption, onSelect: { [weak self] option in
            guard let self = self else { return }
            self.timerManager.updateTimerSound(id: self.timerID, option: option)
        }))
        navigationController?.pushViewController(vc, animated: true)
    }
}
