//
//  TimerEditViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import UIKit
import SnapKit

final class TimerEditViewController: BaseViewController {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "타이머 수정"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .gray800
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .gray600
        return button
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "타이머 이름"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray800
        return label
    }()

    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "예: 파스타 삶기, 오븐 굽기"
        tf.font = .systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.backgroundColor = .gray50
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        return tf
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "시간 설정"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray800
        return label
    }()

    private let timePicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()

    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("수정하기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
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

    var initialName: String = "타이머"
    var initialSeconds: Int = 0
    var onSave: ((String, Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPicker()
        applyInitialValues()
        setupActions()
        setupKeyboardDismiss()
    }

    override func setBackgroundColor() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    private func setupUI() {
        view.addSubview(containerView)

        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(nameLabel)
        containerView.addSubview(nameTextField)
        containerView.addSubview(timeLabel)
        containerView.addSubview(timePicker)
        containerView.addSubview(applyButton)

        containerView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(500)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.equalToSuperview().offset(20)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.size.equalTo(24)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(20)
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
        }

        timePicker.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(150)
        }

        applyButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(52)
        }
    }

    private func setupPicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
    }

    private func applyInitialValues() {
        nameTextField.text = initialName
        let parts = TimerSettings.split(seconds: initialSeconds)
        selectedHours = parts.hours
        selectedMinutes = parts.minutes
        selectedSeconds = parts.seconds

        timePicker.selectRow(selectedHours, inComponent: 0, animated: false)
        timePicker.selectRow(selectedMinutes, inComponent: 1, animated: false)
        timePicker.selectRow(selectedSeconds, inComponent: 2, animated: false)
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func applyTapped() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = (name?.isEmpty == false) ? name! : "타이머"
        let totalSeconds = selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
        guard totalSeconds > 0 else {
            showAlert(title: "알림", message: "타이머 시간을 설정해주세요.")
            return
        }
        onSave?(finalName, totalSeconds)
        dismiss(animated: true)
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        tapGesture.addTarget(self, action: #selector(endEditing))
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension TimerEditViewController: UIPickerViewDataSource {
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

extension TimerEditViewController: UIPickerViewDelegate {
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
