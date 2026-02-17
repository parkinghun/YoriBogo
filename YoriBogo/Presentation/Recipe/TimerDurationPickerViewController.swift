//
//  TimerDurationPickerViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import UIKit
import SnapKit

final class TimerDurationPickerViewController: BaseViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "타이머 설정"
        label.font = AppFont.sectionTitle
        label.textColor = .gray800
        return label
    }()

    private let timePicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()

    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("설정", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = AppFont.button
        button.backgroundColor = .brandOrange500
        button.layer.cornerRadius = 12
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.gray600, for: .normal)
        button.titleLabel?.font = AppFont.button
        return button
    }()

    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    private let seconds = Array(0...59)

    private var selectedHours = 0
    private var selectedMinutes = 0
    private var selectedSeconds = 0

    var initialSeconds: Int = 0
    var onApply: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPicker()
        applyInitialValue()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = .gray50

        view.addSubview(titleLabel)
        view.addSubview(cancelButton)
        view.addSubview(timePicker)
        view.addSubview(applyButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().inset(20)
        }

        cancelButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        timePicker.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(160)
        }

        applyButton.snp.makeConstraints {
            $0.top.equalTo(timePicker.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }

    private func setupPicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
    }

    private func applyInitialValue() {
        let parts = TimerSettings.split(seconds: initialSeconds)
        selectedHours = parts.hours
        selectedMinutes = parts.minutes
        selectedSeconds = parts.seconds

        timePicker.selectRow(selectedHours, inComponent: 0, animated: false)
        timePicker.selectRow(selectedMinutes, inComponent: 1, animated: false)
        timePicker.selectRow(selectedSeconds, inComponent: 2, animated: false)
    }

    private func setupActions() {
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    @objc private func applyTapped() {
        let totalSeconds = selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
        guard totalSeconds > 0 else {
            showAlert(title: "알림", message: "타이머 시간을 설정해주세요.")
            return
        }
        onApply?(totalSeconds)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension TimerDurationPickerViewController: UIPickerViewDataSource {
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

extension TimerDurationPickerViewController: UIPickerViewDelegate {
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
