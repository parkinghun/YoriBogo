//
//  TimerAddViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class TimerAddViewController: BaseViewController {
 
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "새 타이머 추가"
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
        button.setTitle("타이머 적용하기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        button.backgroundColor = .brandOrange500
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    // MARK: - Properties
    private let viewModel = TimerAddViewModel()
    private let disposeBag = DisposeBag()

    // Picker data
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    private let seconds = Array(0...59)

    // Relays for picker selection
    private let hoursRelay = BehaviorRelay<Int>(value: 0)
    private let minutesRelay = BehaviorRelay<Int>(value: 0)
    private let secondsRelay = BehaviorRelay<Int>(value: 0)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPicker()
        bind()
        setupKeyboardDismiss()
    }

    override func setBackgroundColor() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    // MARK: - Setup
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

    // MARK: - Bind
    private func bind() {
        let input = TimerAddViewModel.Input(
            viewDidLoad: Observable.just(()),
            timerName: nameTextField.rx.text.orEmpty.asObservable(),
            hours: hoursRelay.asObservable(),
            minutes: minutesRelay.asObservable(),
            seconds: secondsRelay.asObservable(),
            applyButtonTap: applyButton.rx.tap.asObservable(),
            closeButtonTap: closeButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 적용 버튼 활성화 상태
        output.isApplyButtonEnabled
            .drive(with: self) { owner, isEnabled in
                owner.applyButton.isEnabled = isEnabled
                owner.applyButton.backgroundColor = isEnabled ? .brandOrange500 : .gray300
            }
            .disposed(by: disposeBag)

        // 닫기
        output.dismiss
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Keyboard
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .subscribe(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - UIPickerViewDataSource
extension TimerAddViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3 // 시간, 분, 초
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return hours.count      // 0-23
        case 1: return minutes.count    // 0-59
        case 2: return seconds.count    // 0-59
        default: return 0
        }
    }
}

// MARK: - UIPickerViewDelegate
extension TimerAddViewController: UIPickerViewDelegate {
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
        case 0:
            hoursRelay.accept(hours[row])
        case 1:
            minutesRelay.accept(minutes[row])
        case 2:
            secondsRelay.accept(seconds[row])
        default:
            break
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.width / 3
    }
}
