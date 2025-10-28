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

        // 섹션 데이터
        output.sections
            .drive(with: self) { owner, sections in
                owner.sections = sections
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        // 알림 시간
        output.notificationTime
            .drive(with: self) { owner, time in
                owner.notificationTimeValue = time
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        // 앱 버전
        output.appVersion
            .drive(with: self) { owner, version in
                owner.appVersionValue = version
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        // 아이템 선택
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
            // TODO: 소비기한 알림 시점 선택 화면으로 이동
            print("✅ 소비기한 알림 시점 선택")

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
            // 값 표시 전용 (클릭 불가)
            break

        case .inquiry:
            // TODO: 문의하기 (메일 앱 or 외부 링크)
            print("✅ 문의하기")

        case .privacyPolicy:
            // TODO: 개인정보 처리방침 (웹뷰 or 외부 링크)
            print("✅ 개인정보 처리방침")
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
