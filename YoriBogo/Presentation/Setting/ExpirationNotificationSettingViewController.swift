//
//  ExpirationNotificationSettingViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 11/2/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class ExpirationNotificationSettingViewController: BaseViewController {

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .gray50
        sv.showsVerticalScrollIndicator = true
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray50
        return view
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .gray50
        tv.register(NotificationDayToggleCell.self, forCellReuseIdentifier: NotificationDayToggleCell.id)
        tv.rowHeight = 56
        tv.separatorStyle = .singleLine
        tv.isScrollEnabled = false
        return tv
    }()

    private let timeSettingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "알림 시간"
        label.font = AppFont.itemTitle
        label.textColor = .gray800
        label.numberOfLines = 1
        return label
    }()

    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")

        var components = DateComponents()
        components.hour = 17
        components.minute = 0
        if let date = Calendar.current.date(from: components) {
            picker.date = date
        }

        return picker
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "설정 변경사항은 다음 날 자정(00:00)부터 적용됩니다."
        label.font = AppFont.caption
        label.textColor = .systemOrange
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = AppFont.button
        button.backgroundColor = .brandOrange500
        button.layer.cornerRadius = 12
        return button
    }()

    private let disposeBag = DisposeBag()
    private var notificationDays: [NotificationDay] = [
        NotificationDay(daysBeforeExpiration: 7, isEnabled: false),
        NotificationDay(daysBeforeExpiration: 5, isEnabled: false),
        NotificationDay(daysBeforeExpiration: 3, isEnabled: true),
        NotificationDay(daysBeforeExpiration: 1, isEnabled: true),
        NotificationDay(daysBeforeExpiration: 0, isEnabled: true)
    ]

    private var originalNotificationDays: [NotificationDay] = []
    private var originalTime: Date = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupLayout()
        bind()
        saveInitialState()
    }

    private func setupNavigation() {
        setNavigationTitle("소비기한 알림 설정")
    }

    private func setupUI() {
        view.backgroundColor = .gray50

        view.addSubview(scrollView)
        view.addSubview(infoLabel)
        view.addSubview(saveButton)

        scrollView.addSubview(contentView)

        [tableView, timeSettingContainerView].forEach {
            contentView.addSubview($0)
        }

        [timeLabel, timePicker].forEach {
            timeSettingContainerView.addSubview($0)
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupLayout() {
        scrollView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(infoLabel.snp.top).offset(-12)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        tableView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(56 * 5 + 60) // 5개 셀 + 헤더 여백
        }

        timeSettingContainerView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(280)
            $0.bottom.equalToSuperview().inset(20)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.equalToSuperview().inset(20)
            $0.height.greaterThanOrEqualTo(24)
        }

        timePicker.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().inset(20)
        }

        infoLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.bottom.equalTo(saveButton.snp.top).offset(-12)
        }

        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
    }

    private func bind() {
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveSettings()
            })
            .disposed(by: disposeBag)

        timePicker.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                self?.updateSaveButtonState()
            })
            .disposed(by: disposeBag)
    }

    private func saveInitialState() {
        originalNotificationDays = notificationDays
        originalTime = timePicker.date
        updateSaveButtonState()
    }

    private func updateSaveButtonState() {
        let hasChanges = self.hasChanges()
        saveButton.isEnabled = hasChanges
        saveButton.alpha = hasChanges ? 1.0 : 0.5
    }

    private func hasChanges() -> Bool {
        for (index, day) in notificationDays.enumerated() {
            if day.isEnabled != originalNotificationDays[index].isEnabled {
                return true
            }
        }

        let calendar = Calendar.current
        let originalComponents = calendar.dateComponents([.hour, .minute], from: originalTime)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: timePicker.date)

        if originalComponents.hour != currentComponents.hour ||
           originalComponents.minute != currentComponents.minute {
            return true
        }

        return false
    }

    private func saveSettings() {
        print("저장 버튼 탭됨")
        print("활성화된 날짜: \(notificationDays.filter { $0.isEnabled }.map { $0.daysBeforeExpiration })")

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        print("알림 시간: \(formatter.string(from: timePicker.date))")

        saveInitialState()
        showSaveCompletionAlert()
    }

    private func showSaveCompletionAlert() {
        let alert = UIAlertController(
            title: "소비기한 알림 변경 완료",
            message: "변경사항은 다음 날 자정(00:00)부터 적용됩니다.",
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }

        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ExpirationNotificationSettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationDays.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NotificationDayToggleCell.id,
            for: indexPath
        ) as? NotificationDayToggleCell else {
            return UITableViewCell()
        }

        let day = notificationDays[indexPath.row]
        cell.configure(day: day)

        cell.onToggleChanged = { [weak self] isOn in
            self?.notificationDays[indexPath.row].isEnabled = isOn
            self?.updateSaveButtonState()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "알림 받을 날짜"
    }
}

// MARK: - UITableViewDelegate
extension ExpirationNotificationSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NotificationDay Model
struct NotificationDay {
    let daysBeforeExpiration: Int
    var isEnabled: Bool

    var displayText: String {
        switch daysBeforeExpiration {
        case 0:
            return "당일 (D-day)"
        default:
            return "\(daysBeforeExpiration)일 전 (D-\(daysBeforeExpiration))"
        }
    }
}

// MARK: - NotificationDayToggleCell
final class NotificationDayToggleCell: UITableViewCell {
    static let id = "NotificationDayToggleCell"

    var onToggleChanged: ((Bool) -> Void)?

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body
        label.textColor = .gray800
        return label
    }()

    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .brandOrange500
        return toggle
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none

        contentView.addSubview(dayLabel)
        contentView.addSubview(toggleSwitch)

        dayLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        toggleSwitch.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }

    private func setupActions() {
        toggleSwitch.addTarget(self, action: #selector(toggleValueChanged), for: .valueChanged)
    }

    @objc private func toggleValueChanged() {
        onToggleChanged?(toggleSwitch.isOn)
    }

    func configure(day: NotificationDay) {
        dayLabel.text = day.displayText
        toggleSwitch.isOn = day.isEnabled
    }
}
