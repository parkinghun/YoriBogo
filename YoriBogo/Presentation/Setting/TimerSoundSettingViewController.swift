//
//  TimerSoundSettingViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import UIKit
import AudioToolbox
import SnapKit

final class TimerSoundSettingViewController: BaseViewController {

    enum Mode {
        case globalDefault
        case perTimer(current: TimerSoundOption, onSelect: (TimerSoundOption) -> Void)
    }

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .gray50
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "SoundCell")
        tv.rowHeight = 56
        tv.separatorStyle = .singleLine
        return tv
    }()

    private let mode: Mode
    private var selectedOption: TimerSoundOption

    init(mode: Mode = .globalDefault) {
        self.mode = mode
        switch mode {
        case .globalDefault:
            self.selectedOption = TimerSettings.selectedSoundOption()
        case .perTimer(let current, _):
            self.selectedOption = current
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
    }

    private func setupNavigation() {
        setNavigationTitle("알림음")
    }

    private func setupUI() {
        view.backgroundColor = .gray50
        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension TimerSoundSettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TimerSettings.soundOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = TimerSettings.soundOptions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCell", for: indexPath)

        var content = cell.defaultContentConfiguration()
        content.text = option.title
        content.textProperties.font = AppFont.body
        content.textProperties.color = .gray800
        cell.contentConfiguration = content
        cell.backgroundColor = .white
        cell.selectionStyle = .default
        cell.accessoryType = (option == selectedOption) ? .checkmark : .none
        return cell
    }
}

extension TimerSoundSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = TimerSettings.soundOptions[indexPath.row]
        selectedOption = option
        switch mode {
        case .globalDefault:
            TimerSettings.saveSound(option)
            TimerManager.shared.rescheduleRunningTimerNotifications()
        case .perTimer(_, let onSelect):
            onSelect(option)
        }
        AudioServicesPlaySystemSound(SystemSoundID(option.systemSoundID))
        tableView.reloadData()
    }
}
