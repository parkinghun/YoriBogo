//
//  TimerManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import UIKit
import AudioToolbox
import RxCocoa
import UserNotifications
import RealmSwift

/// 타이머 관리 싱글톤
final class TimerManager {
    static let shared = TimerManager()

    // MARK: - Properties
    private let legacyUserDefaultsKey = "cooking_timers"
    private var tickTimer: DispatchSourceTimer?

    /// Realm 변경 감지 토큰 (Widget Intent 등 외부 프로세스 변경 구독)
    private var realmNotificationToken: NotificationToken?
    /// Realm 초기 로드 완료 후 복원 로직을 1회만 수행하기 위한 플래그
    private var didRestoreOnInitialLoad = false

    /// 타이머 목록 (RxSwift)
    private let timersRelay = BehaviorRelay<[TimerItem]>(value: [])
    var timers: Driver<[TimerItem]> {
        return timersRelay.asDriver()
    }

    // MARK: - Initialization
    private init() {
        setupRealmObservation()   // Realm 변경 구독 시작 (.initial 콜백으로 초기 데이터 로드)
        startTick()
    }

    deinit {
        stopTick()
        realmNotificationToken?.invalidate()
        realmNotificationToken = nil
    }

    // MARK: - Tick Mechanism (1Hz)

    /// 1Hz 틱 시작 (단일 타이머로 모든 타이머 갱신)
    private func startTick() {
        let queue = DispatchQueue(label: "com.yoribogo.timer", qos: .userInteractive)
        tickTimer = DispatchSource.makeTimerSource(queue: queue)
        tickTimer?.schedule(deadline: .now(), repeating: 1.0)

        tickTimer?.setEventHandler { [weak self] in
            self?.tick()
        }

        tickTimer?.resume()
    }

    private func stopTick() {
        tickTimer?.cancel()
        tickTimer = nil
    }

    private func remainingSeconds(until endDate: Date, now: Date = Date()) -> Int {
        max(0, Int(ceil(endDate.timeIntervalSince(now))))
    }

    /// 매 초마다 호출 - wall-clock 기준으로 남은 시간 재계산
    private func tick() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let snapshot = self.timersRelay.value
            var updated = false
            var pendingRemainingByID: [UUID: Int] = [:]

            for timer in snapshot {
                guard timer.isRunning,
                      let endDate = timer.endDate else { continue }

                let remaining = self.remainingSeconds(until: endDate)
                pendingRemainingByID[timer.id] = remaining

                if remaining <= 0 {
                    // 외부(Widget/Intent)에서 방금 상태가 바뀐 경우, 최신 상태를 기준으로 완료 처리 여부를 재검증
                    let latest = self.timersRelay.value.first(where: { $0.id == timer.id })
                    guard latest?.isRunning == true else { continue }
                    self.completeTimer(id: timer.id)
                    updated = true
                }
            }

            if updated {
                // completeTimer() → saveTimers() 흐름에서 relay가 직접 업데이트되므로 별도 처리 불필요
            } else if !pendingRemainingByID.isEmpty {
                // 최신 relay 상태에 남은 시간만 병합 적용해, 외부 변경(isRunning/endDate)을 덮어쓰지 않음
                var latestTimers = self.timersRelay.value
                var didChange = false

                for i in 0..<latestTimers.count {
                    guard latestTimers[i].isRunning,
                          latestTimers[i].endDate != nil,
                          let pendingRemaining = pendingRemainingByID[latestTimers[i].id] else { continue }

                    if latestTimers[i].remainingSeconds != pendingRemaining {
                        latestTimers[i].remainingSeconds = pendingRemaining
                        didChange = true
                    }
                }

                if didChange {
                    self.timersRelay.accept(latestTimers)
                }
            }
        }
    }

    // MARK: - CRUD Operations

    func timer(byRecipeStepID recipeStepID: String) -> TimerItem? {
        return timersRelay.value.first(where: { $0.recipeStepID == recipeStepID })
    }

    @discardableResult
    func upsertRecipeStepTimer(recipeStepID: String, title: String, duration: TimeInterval) -> TimerItem {
        var timers = timersRelay.value
        let totalSeconds = Int(duration)

        if let index = timers.firstIndex(where: { $0.recipeStepID == recipeStepID }) {
            timers[index].totalSeconds = totalSeconds
            if !timers[index].isRunning {
                timers[index].remainingSeconds = totalSeconds
                timers[index].startDate = nil
                timers[index].endDate = nil
            }
            saveTimers(timers)
            return timers[index]
        }

        let timer = TimerItem(
            name: title,
            totalSeconds: totalSeconds,
            recipeStepID: recipeStepID
        )
        timers.insert(timer, at: 0)
        saveTimers(timers)
        return timer
    }

    /// 타이머 생성
    @discardableResult
    func createTimer(title: String, duration: TimeInterval, recipeStepID: String? = nil) -> UUID {
        var timers = timersRelay.value
        let timer = TimerItem(
            name: title,
            totalSeconds: Int(duration),
            recipeStepID: recipeStepID
        )
        timers.insert(timer, at: 0)
        saveTimers(timers)
        return timer.id
    }

    /// 타이머 시작
    func startTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        let now = Date()
        timers[index].isRunning = true
        timers[index].startDate = now
        timers[index].endDate = now.addingTimeInterval(TimeInterval(timers[index].remainingSeconds))

        saveTimers(timers)
        scheduleNotification(for: timers[index])
        if #available(iOS 17.1, *) {
            LiveActivityManager.shared.start(for: timers[index])
        }
    }

    /// 타이머 일시정지
    func pauseTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }),
              timers[index].isRunning,
              let endDate = timers[index].endDate else { return }

        let remaining = remainingSeconds(until: endDate)

        timers[index].remainingSeconds = remaining
        timers[index].isRunning = false
        timers[index].startDate = nil
        timers[index].endDate = nil
        timers[index].pausedDate = Date()

        saveTimers(timers)
        cancelNotification(id: id)
        if #available(iOS 17.1, *) {
            LiveActivityManager.shared.update(for: timers[index])
        }
    }

    /// 타이머 재시작 (완료된 타이머를 처음부터 다시 시작)
    func restartTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        timers[index].remainingSeconds = timers[index].totalSeconds
        timers[index].isRunning = false
        timers[index].startDate = nil
        timers[index].endDate = nil

        saveTimers(timers)
        startTimer(id: id)
    }

    /// 타이머 취소 (실행 중단 + 초기 상태 리셋, 삭제하지 않음)
    func cancelTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        let timerToEnd = timers[index]

        timers[index].remainingSeconds = timers[index].totalSeconds
        timers[index].isRunning = false
        timers[index].startDate = nil
        timers[index].endDate = nil
        timers[index].pausedDate = nil

        saveTimers(timers)
        cancelNotification(id: id)
        if #available(iOS 17.1, *) {
            LiveActivityManager.shared.end(for: timerToEnd)
        }
    }

    /// 타이머 완전 삭제
    func deleteTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        let timerToEnd = timers[index]
        timers.remove(at: index)

        saveTimers(timers)
        cancelNotification(id: id)
        if #available(iOS 17.1, *) {
            LiveActivityManager.shared.end(for: timerToEnd)
        }
    }

    /// 타이머 완료 처리
    private func completeTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        let completedTimer = timers[index]

        timers[index].isRunning = false
        timers[index].remainingSeconds = 0
        timers[index].startDate = nil
        timers[index].endDate = nil

        saveTimers(timers)

        // 포그라운드 완료 시 예약 알림 취소
        cancelNotification(id: id)
        if #available(iOS 17.1, *) {
            LiveActivityManager.shared.end(for: completedTimer)
        }

        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 사운드 재생
        playTimerSound(for: completedTimer)
    }

    // MARK: - Persistence

    /// Realm 변경사항을 지속적으로 관찰하여 timersRelay 자동 업데이트
    /// - .initial: 앱 최초 로드 시 Legacy 마이그레이션 처리 후 Relay 업데이트
    /// - .update: Widget Intent 등 외부 프로세스가 Realm을 변경했을 때 자동 수신
    private func setupRealmObservation() {
        TimerRealmStore.migrateFromDefaultRealmIfNeeded()

        guard let realm = try? TimerRealmStore.realm() else { return }

        let results = realm.objects(CookingTimerObject.self)
            .sorted(byKeyPath: "createdAt", ascending: false)

        realmNotificationToken = results.observe { [weak self] changes in
            guard let self else { return }

            switch changes {
            case .initial(let collection):
                let timers = collection.map { self.timerItem(from: $0) }
                if timers.isEmpty, let legacyTimers = self.loadLegacyTimers() {
                    // Legacy UserDefaults 데이터를 Realm으로 마이그레이션
                    self.saveTimers(legacyTimers)
                    UserDefaults.standard.removeObject(forKey: self.legacyUserDefaultsKey)
                } else {
                    self.timersRelay.accept(Array(timers))
                    if #available(iOS 17.1, *) {
                        LiveActivityManager.shared.sync(with: Array(timers))
                    }
                }
                self.restoreTimersIfNeededOnInitialLoad()

            case .update(let collection, _, _, _):
                // Widget Intent 등 외부 프로세스 변경 감지 - endDate 기반으로 remainingSeconds 재계산
                let timers = collection.map { obj -> TimerItem in
                    var item = self.timerItem(from: obj)
                    if item.isRunning, let endDate = item.endDate {
                        item.remainingSeconds = self.remainingSeconds(until: endDate)
                    }
                    return item
                }
                self.timersRelay.accept(Array(timers))
                if #available(iOS 17.1, *) {
                    LiveActivityManager.shared.sync(with: Array(timers))
                }

            case .error:
                break
            }
        }
    }

    private func restoreTimersIfNeededOnInitialLoad() {
        guard !didRestoreOnInitialLoad else { return }
        didRestoreOnInitialLoad = true
        restoreTimers()
    }

    /// Realm에 저장
    private func saveTimers(_ timers: [TimerItem]) {
        do {
            let realm = try TimerRealmStore.realm()
            try realm.write {
                let ids = timers.map { $0.id.uuidString }
                let toDelete = realm.objects(CookingTimerObject.self).filter("NOT id IN %@", ids)
                realm.delete(toDelete)

                for timer in timers {
                    let object = realm.object(ofType: CookingTimerObject.self, forPrimaryKey: timer.id.uuidString) ?? CookingTimerObject()
                    if object.realm == nil {
                        object.id = timer.id.uuidString
                    }
                    object.title = timer.name
                    object.totalSeconds = timer.totalSeconds
                    object.remainingSeconds = timer.remainingSeconds
                    object.isRunning = timer.isRunning
                    object.startDate = timer.startDate
                    object.endDate = timer.endDate
                    object.pausedDate = timer.pausedDate
                    object.soundID = timer.soundID
                    object.soundSystemSoundID = timer.soundSystemSoundID
                    object.recipeStepID = timer.recipeStepID
                    object.createdAt = timer.createdAt

                    realm.add(object, update: .modified)
                }
            }
        } catch { }

        // 로컬 write는 Notification을 기다리지 않고 relay를 직접 업데이트
        timersRelay.accept(timers)
        syncSharedStatesFromApp(timers)
    }

    private func syncSharedStatesFromApp(_ timers: [TimerItem]) {
        let now = Date()
        let currentStates = TimerSharedStateStore.statesByTimerID()
        var nextStatesByID: [String: SharedTimerState] = [:]
        nextStatesByID.reserveCapacity(timers.count)

        for timer in timers {
            let timerID = timer.id.uuidString
            let previousVersion = currentStates[timerID]?.version ?? -1
            let state = normalizedSharedState(from: timer, previousVersion: previousVersion, now: now)
            nextStatesByID[timerID] = state
        }

        let activeTimerID = activeSharedTimerID(from: timers, statesByTimerID: nextStatesByID)
        TimerSharedStateStore.replaceAll(
            statesByTimerID: nextStatesByID,
            activeTimerID: activeTimerID
        )
    }

    private func normalizedSharedState(from timer: TimerItem, previousVersion: Int, now: Date) -> SharedTimerState {
        var normalizedStartTime = timer.startDate
        var normalizedEndTime = timer.endDate
        var normalizedIsRunning = timer.isRunning
        var normalizedRemaining = max(0, timer.remainingSeconds)

        if normalizedIsRunning, let endTime = normalizedEndTime {
            // 완료 시각이 경과된 running 상태는 공유 상태에선 완료로 정규화한다.
            normalizedRemaining = remainingSeconds(until: endTime, now: now)
            if normalizedRemaining <= 0 {
                normalizedIsRunning = false
                normalizedStartTime = nil
                normalizedEndTime = nil
            }
        } else if normalizedIsRunning {
            // endTime이 없는 running 비정상 상태 방어
            normalizedIsRunning = false
            normalizedStartTime = nil
        }

        return SharedTimerState(
            timerID: timer.id.uuidString,
            title: timer.name,
            startTime: normalizedStartTime,
            endTime: normalizedEndTime,
            isRunning: normalizedIsRunning,
            remainingSeconds: normalizedRemaining,
            lastUpdatedAt: now,
            version: previousVersion + 1,
            writer: SharedTimerStateWriter.app
        )
    }

    private func activeSharedTimerID(
        from timers: [TimerItem],
        statesByTimerID: [String: SharedTimerState]
    ) -> String? {
        let runningStates = statesByTimerID.values.filter { $0.isRunning }
        if let running = runningStates.sorted(by: { lhs, rhs in
            let leftEnd = lhs.endTime ?? .distantFuture
            let rightEnd = rhs.endTime ?? .distantFuture
            if leftEnd == rightEnd {
                return lhs.lastUpdatedAt > rhs.lastUpdatedAt
            }
            return leftEnd < rightEnd
        }).first {
            return running.timerID
        }

        return timers.first?.id.uuidString
    }

    private func timerItem(from object: CookingTimerObject) -> TimerItem {
        let id = UUID(uuidString: object.id) ?? UUID()
        var item = TimerItem(
            id: id,
            name: object.title,
            totalSeconds: object.totalSeconds,
            recipeStepID: object.recipeStepID,
            createdAt: object.createdAt,
            soundID: object.soundID,
            soundSystemSoundID: object.soundSystemSoundID
        )
        item.remainingSeconds = object.remainingSeconds
        item.isRunning = object.isRunning
        item.startDate = object.startDate
        item.endDate = object.endDate
        item.pausedDate = object.pausedDate
        return item
    }

    private func loadLegacyTimers() -> [TimerItem]? {
        guard let data = UserDefaults.standard.data(forKey: legacyUserDefaultsKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode([TimerItem].self, from: data)
    }


    /// 앱 시작 시 타이머 복원
    func restoreTimers() {
        var timers = timersRelay.value
        var updated = false

        for i in 0..<timers.count {
            guard timers[i].isRunning,
                  let endDate = timers[i].endDate else { continue }

            let remaining = remainingSeconds(until: endDate)

            if remaining <= 0 {
                // 이미 완료된 타이머
                timers[i].isRunning = false
                timers[i].remainingSeconds = 0
                timers[i].startDate = nil
                timers[i].endDate = nil
                updated = true
            } else {
                // 남은 시간 업데이트 및 알림 재스케줄
                timers[i].remainingSeconds = remaining
                scheduleNotification(for: timers[i])
                if #available(iOS 17.1, *) {
                    LiveActivityManager.shared.start(for: timers[i])
                }
            }
        }

        if updated {
            saveTimers(timers)
        }

    }

    // MARK: - Notifications

    /// 알림 스케줄
    private func scheduleNotification(for timer: TimerItem) {
        guard let endDate = timer.endDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(timer.name) 타이머 완료!"
        content.body = "타이머가 종료되었습니다"
        content.sound = getNotificationSound(for: timer)
        content.categoryIdentifier = "TIMER_CATEGORY"

        // endDate를 사용하여 정확한 종료 시간으로 스케줄
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: endDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "timer_\(timer.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// 알림 취소
    private func cancelNotification(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_\(id.uuidString)"])
    }

    /// 모든 실행 중인 타이머의 알림 스케줄 (백그라운드 진입 시)
    func scheduleAllNotifications() {
        let runningTimers = timersRelay.value.filter { $0.isRunning }
        for timer in runningTimers {
            scheduleNotification(for: timer)
        }
    }

    /// 실행 중인 타이머 알림 재스케줄 (사운드 변경 등)
    func rescheduleRunningTimerNotifications() {
        let runningTimers = timersRelay.value.filter { $0.isRunning }
        for timer in runningTimers {
            cancelNotification(id: timer.id)
            scheduleNotification(for: timer)
        }
    }

    /// 남은 시간 재계산 (포어그라운드 복귀 시)
    func recalculateTimers() {
        tick()
    }

    // MARK: - Sound

    /// 알림 사운드 가져오기
    private func getNotificationSound(for timer: TimerItem) -> UNNotificationSound {
        let soundName = timer.soundID
        guard soundName != "default",
              Bundle.main.path(forResource: soundName, ofType: "caf") != nil else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundName).caf"))
    }

    /// 타이머 완료 사운드 재생
    private func playTimerSound(for timer: TimerItem) {
        let systemSoundID = timer.soundSystemSoundID > 0
            ? SystemSoundID(timer.soundSystemSoundID)
            : SystemSoundID(TimerSettings.selectedSoundOption().systemSoundID)
        AudioServicesPlaySystemSound(systemSoundID)
    }

    // MARK: - Timer Sound

    func updateTimerSound(id: UUID, option: TimerSoundOption) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        timers[index].soundID = option.id
        timers[index].soundSystemSoundID = option.systemSoundID
        saveTimers(timers)

        if timers[index].isRunning {
            cancelNotification(id: timers[index].id)
            scheduleNotification(for: timers[index])
        }
    }

    func updateTimer(id: UUID, name: String, duration: TimeInterval) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        let totalSeconds = Int(duration)
        timers[index].name = name
        timers[index].totalSeconds = totalSeconds

        if timers[index].isRunning {
            let now = Date()
            timers[index].remainingSeconds = totalSeconds
            timers[index].startDate = now
            timers[index].endDate = now.addingTimeInterval(TimeInterval(totalSeconds))
            scheduleNotification(for: timers[index])
            if #available(iOS 17.1, *) {
                LiveActivityManager.shared.update(for: timers[index])
            }
        } else {
            timers[index].remainingSeconds = totalSeconds
            timers[index].startDate = nil
            timers[index].endDate = nil
            cancelNotification(id: timers[index].id)
            if #available(iOS 17.1, *) {
                LiveActivityManager.shared.update(for: timers[index])
            }
        }

        saveTimers(timers)
    }
}
