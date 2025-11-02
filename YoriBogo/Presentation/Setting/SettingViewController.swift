//
//  SettingViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import MessageUI
import SafariServices
import UserNotifications

final class SettingViewController: BaseViewController {

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .gray50
        tv.register(SettingCell.self, forCellReuseIdentifier: SettingCell.id)
        tv.rowHeight = 56
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 20)
        return tv
    }()

    // MARK: - Properties
    private let viewModel = SettingViewModel()
    private let disposeBag = DisposeBag()
    private var sections: [SettingSection] = []
    private var notificationTimeValue: String = ""
    private var appVersionValue: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        bind()
    }

    // MARK: - Setup
    private func setupNavigation() {
        setNavigationTitle("설정")
    }

    private func setupUI() {
        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Bind
    private func bind() {
        let input = SettingViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: tableView.rx.itemSelected.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.sections
            .drive(with: self) { owner, sections in
                owner.sections = sections
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        output.notificationTime
            .drive(with: self) { owner, time in
                owner.notificationTimeValue = time
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        output.appVersion
            .drive(with: self) { owner, version in
                owner.appVersionValue = version
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        output.itemSelected
            .drive(with: self) { owner, item in
                owner.handleItemSelection(item)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    private func handleItemSelection(_ item: SettingItem) {
        switch item {
        case .notificationTiming:
            checkNotificationPermission()

        case .notificationTime:
            // 값 표시 전용 (클릭 불가)
            break

        case .timerSound:
            // TODO: 알림음 선택 화면으로 이동
            print("✅ 알림음 선택")

        case .defaultTimerDuration:
            // TODO: 기본 타이머 시간 선택 화면으로 이동
            print("✅ 기본 타이머 시간 선택")

        case .monthlyStats:
            // TODO: 이번 달 소비/폐기 현황 화면으로 이동
            print("✅ 이번 달 소비/폐기 현황")

        case .appVersion:
            break

        case .inquiry:
            presentEmailComposer()

        case .privacyPolicy:
            presentPrivacyPolicy()
        }
    }

    private func getCellValue(for item: SettingItem) -> String? {
        switch item {
        case .notificationTime:
            return notificationTimeValue
        case .appVersion:
            return appVersionValue
        default:
            return nil
        }
    }

    // MARK: - Navigation
    private func presentEmailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            showAlert(
                title: "메일 앱을 사용할 수 없습니다",
                message: "기기의 메일 설정을 확인해주세요."
            )
            return
        }

        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients([Bundle.getSecrets(for: .developerEmail)])
        composer.setSubject("[요리보고] 문의하기")
        composer.setMessageBody("""


            ---
            앱 버전: \(appVersionValue)
            기기: \(UIDevice.current.model)
            iOS: \(UIDevice.current.systemVersion)
            """, isHTML: false)

        present(composer, animated: true)
    }

    private func presentPrivacyPolicy() {
        guard let url = URL(string: Bundle.getSecrets(for: .PrivacyPolicyURL)) else {
            showAlert(title: "오류", message: "잘못된 URL입니다.")
            return
        }

        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .brandOrange500
        present(safariVC, animated: true)
    }

    // MARK: - Notification Permission
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // 처음 요청 - 시스템 권한 요청
                    self?.requestNotificationPermission()

                case .authorized:
                    // 권한 허용됨 - 설정 화면으로 이동
                    self?.presentExpirationNotificationSettingVC()

                case .denied:
                    // 권한 거부됨 - 설정 안내 Alert
                    self?.showNotificationPermissionDeniedAlert()

                default:
                    break
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "오류", message: error.localizedDescription)
                    return
                }

                if granted {
                    // 권한 승인됨 - 설정 화면으로 이동
                    self?.presentExpirationNotificationSettingVC()
                } else {
                    // 권한 거부됨
                    self?.showNotificationPermissionDeniedAlert()
                }
            }
        }
    }

    private func presentExpirationNotificationSettingVC() {
        let vc = ExpirationNotificationSettingViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showNotificationPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "알림 권한이 필요합니다",
            message: "소비기한 알림을 받으려면 알림 권한이 필요합니다.\n설정에서 알림을 허용해주세요.",
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(settingsAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingCell.id,
            for: indexPath
        ) as? SettingCell else {
            return UITableViewCell()
        }

        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]

        cell.configure(
            icon: item.icon,
            title: item.title,
            value: getCellValue(for: item),
            cellType: item.cellType
        )

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

// MARK: - UITableViewDelegate
extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - SettingCell
final class SettingCell: UITableViewCell {
    static let id = "SettingCell"

    // MARK: - UI Components
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .brandOrange500
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray800
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray600
        return label
    }()

    private let disclosureImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .gray400
        return iv
    }()

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
        backgroundColor = .white
        selectionStyle = .default

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(disclosureImageView)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        disclosureImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(disclosureImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Configure
    func configure(icon: String?, title: String, value: String?, cellType: SettingCellType) {
        // 아이콘
        if let icon = icon {
            iconImageView.image = UIImage(systemName: icon)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        // 타이틀
        titleLabel.text = title

        // 값
        valueLabel.text = value
        valueLabel.isHidden = (value == nil)

        // 타입에 따른 처리
        switch cellType {
        case .disclosure:
            disclosureImageView.isHidden = false
            selectionStyle = .default

        case .value:
            disclosureImageView.isHidden = true
            selectionStyle = .none

        case .button:
            disclosureImageView.isHidden = false
            selectionStyle = .default
            titleLabel.textColor = .brandOrange500
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension SettingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            showAlert(title: "오류", message: error.localizedDescription)
        }
        controller.dismiss(animated: true)
    }
}
