//
//  DefaultTimerDurationSettingViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import UIKit
import SnapKit

final class DefaultTimerDurationSettingViewController: BaseViewController {

    private let timeSettingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "기본 타이머 시간"
        label.font = AppFont.itemTitle
        label.textColor = .gray800
        return label
    }()

    private let timePicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = AppFont.button
        button.backgroundColor = .brandOrange500
        button.layer.cornerRadius = 12
        return button
    }()

    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    private let seconds = Array(0...59)

    private var selectedHours = 0
    private var selectedMinutes = 0
    private var selectedSeconds = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupPicker()
        applySavedDuration()
        setupActions()
    }

    private func setupNavigation() {
        setNavigationTitle("기본 타이머 시간")
    }

    private func setupUI() {
        view.backgroundColor = .gray50
        view.addSubview(timeSettingContainerView)
        view.addSubview(saveButton)

        timeSettingContainerView.addSubview(timeLabel)
        timeSettingContainerView.addSubview(timePicker)

        timeSettingContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(260)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        timePicker.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().inset(16)
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
    }

    private func setupPicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
    }

    private func applySavedDuration() {
        let defaultSeconds = TimerSettings.defaultDuration()
        let parts = TimerSettings.split(seconds: defaultSeconds)
        selectedHours = parts.hours
        selectedMinutes = parts.minutes
        selectedSeconds = parts.seconds

        timePicker.selectRow(selectedHours, inComponent: 0, animated: false)
        timePicker.selectRow(selectedMinutes, inComponent: 1, animated: false)
        timePicker.selectRow(selectedSeconds, inComponent: 2, animated: false)
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }

    @objc private func saveButtonTapped() {
        let totalSeconds = selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
        TimerSettings.saveDefaultDuration(seconds: totalSeconds)
        navigationController?.popViewController(animated: true)
    }
}

extension DefaultTimerDurationSettingViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return hours.count
        case 1: return minutes.count
        case 2: return seconds.count
        default: return 0
        }
    }
}

extension DefaultTimerDurationSettingViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return "\(hours[row])시간"
        case 1: return "\(minutes[row])분"
        case 2: return "\(seconds[row])초"
        default: return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: selectedHours = hours[row]
        case 1: selectedMinutes = minutes[row]
        case 2: selectedSeconds = seconds[row]
        default: break
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.width / 3
    }
}
