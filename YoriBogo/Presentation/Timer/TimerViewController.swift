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
    private var currentSortOption: TimerSortOption = .createdDesc
    private let showRecipeTimersInTab = false
    private var manualTimers: [TimerItem] = [] {
        didSet {
            updateEmptyState()
        }
    }
    private var recipeTimers: [TimerItem] = []

    private enum TimerSortOption: String, CaseIterable {
        case createdDesc = "최신순"
        case remainingAsc = "남은시간"
        case nameAsc = "이름순"
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

        let sortButton = UIBarButtonItem(
            title: "정렬",
            style: .plain,
            target: self,
            action: #selector(sortButtonTapped)
        )
        sortButton.tintColor = .brandOrange500
        navigationItem.rightBarButtonItems = [addButton, sortButton]
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
                let filteredManualTimers = newTimers.filter { $0.recipeStepID == nil }
                let sortedManualTimers = owner.sortTimers(filteredManualTimers, by: owner.currentSortOption)
                let sortedRecipeTimers = newTimers
                    .filter { $0.recipeStepID != nil }
                    .sorted { $0.createdAt > $1.createdAt }
                // 수동 삭제 중에는 RxSwift 업데이트 무시
                if owner.isDeletingManually {
                    return
                }

                let oldTimers = owner.manualTimers
                owner.manualTimers = sortedManualTimers
                owner.recipeTimers = sortedRecipeTimers

                // 타이머 개수 변경 (추가/삭제)
                if oldTimers.count != sortedManualTimers.count {
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
        NotificationService.shared.requestAuthorization { _ in }
    }

    // MARK: - Actions
    @objc private func presentTimerAddView() {
        let vc = TimerAddViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }

    @objc private func editButtonTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        navigationItem.leftBarButtonItem?.title = tableView.isEditing ? "완료" : "편집"
    }

    @objc private func sortButtonTapped() {
        let alert = UIAlertController(title: "정렬", message: nil, preferredStyle: .actionSheet)

        TimerSortOption.allCases.forEach { option in
            let action = UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.currentSortOption = option
                self.manualTimers = self.sortTimers(self.manualTimers, by: option)
                self.tableView.reloadData()
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func sortTimers(_ timers: [TimerItem], by option: TimerSortOption) -> [TimerItem] {
        switch option {
        case .createdDesc:
            return timers.sorted { $0.createdAt > $1.createdAt }
        case .remainingAsc:
            return timers.sorted { $0.remainingSeconds < $1.remainingSeconds }
        case .nameAsc:
            return timers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    // MARK: - Timer Management
    private func togglePlayPause(at indexPath: IndexPath) {
        let timer = timerForIndexPath(indexPath)

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
        let isEmpty = manualTimers.isEmpty
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        navigationItem.leftBarButtonItem?.isEnabled = !isEmpty
    }
}

// MARK: - UITableViewDataSource
extension TimerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return showRecipeTimersInTab ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showRecipeTimersInTab {
            return section == 0 ? manualTimers.count : recipeTimers.count
        }
        return manualTimers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TimerListCell.identifier,
            for: indexPath
        ) as? TimerListCell else {
            return UITableViewCell()
        }

        let timer = timerForIndexPath(indexPath)
        cell.configure(with: timer)
        cell.onPlayPauseTapped = { [weak self] in
            self?.togglePlayPause(at: indexPath)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard showRecipeTimersInTab else { return nil }
        return section == 0 ? "일반 타이머" : "레시피 타이머"
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
        let timer = timerForIndexPath(indexPath)
        let detailVC = TimerDetailViewController(timer: timer)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 삭제할 타이머 가져오기
            let timer = timerForIndexPath(indexPath)

            // RxSwift 업데이트 일시 중단
            isDeletingManually = true

            // 로컬 배열에서 먼저 제거
            if showRecipeTimersInTab, indexPath.section == 1 {
                recipeTimers.remove(at: indexPath.row)
            } else {
                manualTimers.remove(at: indexPath.row)
            }

            // TableView 애니메이션으로 행 삭제
            tableView.deleteRows(at: [indexPath], with: .automatic)

            // 애니메이션 완료 후 실제 데이터 삭제 및 RxSwift 재개
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.timerManager.deleteTimer(id: timer.id)
                self?.isDeletingManually = false
            }
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "삭제"
    }
}

private extension TimerViewController {
    func timerForIndexPath(_ indexPath: IndexPath) -> TimerItem {
        if showRecipeTimersInTab, indexPath.section == 1 {
            return recipeTimers[indexPath.row]
        }
        return manualTimers[indexPath.row]
    }
}
