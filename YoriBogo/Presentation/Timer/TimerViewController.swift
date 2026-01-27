//
//  TimerViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class TimerViewController: BaseViewController {

    // MARK: - UI Components
    private let emptyView = TimerEmptyView()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = 100 // 아이폰 기본 타이머와 유사한 높이
        tv.register(TimerListCell.self, forCellReuseIdentifier: TimerListCell.identifier)
        tv.delegate = self
        tv.dataSource = self
        tv.isHidden = true
        return tv
    }()

    // MARK: - Properties
    private let timerManager = TimerManager.shared
    private let disposeBag = DisposeBag()
    private var isDeletingManually = false // 수동 삭제 중 플래그
    private var isSwipeEditing = false // 스와이프 삭제 중 플래그
    private var editingIndexPath: IndexPath?
    private var timers: [TimerItem] = [] {
        didSet {
            updateEmptyState()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        setupActions()
        bind()
        updateEmptyState()
        requestNotificationPermission()
    }

    // MARK: - Setup
    private func setupNavigation() {
        setNavigationTitle("타이머")

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(presentTimerAddView)
        )
        addButton.tintColor = .brandOrange500
        navigationItem.rightBarButtonItem = addButton

        let editButton = UIBarButtonItem(
            title: "편집",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        editButton.tintColor = .brandOrange500
        navigationItem.leftBarButtonItem = editButton
    }

    private func configureHierachy() {
        view.addSubview(tableView)
        view.addSubview(emptyView)
    }

    private func configureLayout() {
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func setupActions() {
        emptyView.ctaButton?.addTarget(self, action: #selector(presentTimerAddView), for: .touchUpInside)
    }

    private func bind() {
        // TimerManager의 타이머 리스트 구독
        timerManager.timers
            .drive(with: self) { owner, newTimers in
                // 수동 삭제 중에는 RxSwift 업데이트 무시
                if owner.isDeletingManually {
                    return
                }

                let oldTimers = owner.timers
                owner.timers = newTimers

                // 타이머 개수 변경 (추가/삭제)
                if oldTimers.count != newTimers.count {
                    // 개수 변경 시 fade 애니메이션으로 부드럽게
                    UIView.transition(with: owner.tableView,
                                    duration: 0.25,
                                    options: .transitionCrossDissolve,
                                    animations: {
                        owner.tableView.reloadData()
                    })
                } else {
                    if owner.tableView.isEditing {
                        return
                    }
                    // 시간 업데이트만 (애니메이션 없이)
                    if let visibleIndexPaths = owner.tableView.indexPathsForVisibleRows,
                       !visibleIndexPaths.isEmpty {
                        let indexPathsToReload: [IndexPath]
                        if owner.isSwipeEditing, let editingIndexPath = owner.editingIndexPath {
                            indexPathsToReload = visibleIndexPaths.filter { $0 != editingIndexPath }
                        } else {
                            indexPathsToReload = visibleIndexPaths
                        }
                        UIView.performWithoutAnimation {
                            owner.tableView.reloadRows(at: indexPathsToReload, with: .none)
                        }
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    private func requestNotificationPermission() {
        NotificationService.shared.requestAuthorization { granted in
            if granted {
                print("✅ 타이머 알림 권한 허용")
            } else {
                print("⚠️ 타이머 알림 권한 거부")
            }
        }
    }

    // MARK: - Actions
    @objc private func presentTimerAddView() {
        let vc = TimerAddViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.onTimerCreated = { [weak self] name, totalSeconds in
            self?.addTimer(name: name, totalSeconds: TimeInterval(totalSeconds))
        }
        present(vc, animated: true)
    }

    @objc private func editButtonTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        navigationItem.leftBarButtonItem?.title = tableView.isEditing ? "완료" : "편집"
    }

    // MARK: - Timer Management
    private func addTimer(name: String, totalSeconds: TimeInterval) {
        timerManager.createTimer(title: name, duration: totalSeconds)
    }

    private func deleteTimer(at index: Int) {
        let timer = timers[index]
        timerManager.cancelTimer(id: timer.id)
    }

    private func togglePlayPause(at index: Int) {
        let timer = timers[index]

        if timer.isFinished {
            // 완료된 타이머는 재시작
            timerManager.restartTimer(id: timer.id)
        } else if timer.isRunning {
            // 실행 중이면 일시정지
            timerManager.pauseTimer(id: timer.id)
        } else {
            // 일시정지 상태면 시작
            timerManager.startTimer(id: timer.id)
        }
    }

    private func updateEmptyState() {
        let isEmpty = timers.isEmpty
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        navigationItem.leftBarButtonItem?.isEnabled = !isEmpty
    }
}

// MARK: - UITableViewDataSource
extension TimerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TimerListCell.identifier,
            for: indexPath
        ) as? TimerListCell else {
            return UITableViewCell()
        }

        let timer = timers[indexPath.row]
        cell.configure(with: timer)
        cell.onPlayPauseTapped = { [weak self] in
            self?.togglePlayPause(at: indexPath.row)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TimerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        isSwipeEditing = true
        editingIndexPath = indexPath
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        isSwipeEditing = false
        editingIndexPath = nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timer = timers[indexPath.row]
        let detailVC = TimerDetailViewController(timer: timer)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 삭제할 타이머 가져오기
            let timer = timers[indexPath.row]

            // RxSwift 업데이트 일시 중단
            isDeletingManually = true

            // 로컬 배열에서 먼저 제거
            timers.remove(at: indexPath.row)

            // TableView 애니메이션으로 행 삭제
            tableView.deleteRows(at: [indexPath], with: .automatic)

            // 애니메이션 완료 후 실제 데이터 삭제 및 RxSwift 재개
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.timerManager.cancelTimer(id: timer.id)
                self?.isDeletingManually = false
            }
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "삭제"
    }
}
