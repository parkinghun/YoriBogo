//
//  TimerManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import Foundation
import UIKit
import AudioToolbox
import RxSwift
import RxCocoa
import UserNotifications
import RealmSwift

/// 타이머 관리 싱글톤
final class TimerManager {
    static let shared = TimerManager()

    // MARK: - Properties
    private var tickTimer: DispatchSourceTimer?
    private let disposeBag = DisposeBag()

    /// 타이머 목록 (RxSwift)
    private let timersRelay = BehaviorRelay<[TimerItem]>(value: [])
    var timers: Driver<[TimerItem]> {
        return timersRelay.asDriver()
    }

    // MARK: - Initialization
    private init() {
        loadTimers()
        startTick()
        restoreTimers()
    }

    deinit {
        stopTick()
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

    /// 매 초마다 호출 - wall-clock 기준으로 남은 시간 재계산
    private func tick() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            var timers = self.timersRelay.value
            var updated = false
            var hasRunningTimer = false

            for i in 0..<timers.count {
                guard timers[i].isRunning,
                      let endDate = timers[i].endDate else { continue }
                hasRunningTimer = true

                let remaining = Int(endDate.timeIntervalSince(Date()))

                // 남은 시간 업데이트
                timers[i].remainingSeconds = max(0, remaining)

                // 타이머 완료
                if remaining <= 0 {
                    self.completeTimer(id: timers[i].id)
                    updated = true
                }
            }

            if updated {
                self.loadTimers()
            } else if hasRunningTimer {
                // UI 업데이트를 위해 갱신 트리거
                self.timersRelay.accept(timers)
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
        print("✅ 타이머 생성: \(title), \(Int(duration))초")
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
        print("▶️ 타이머 시작: \(timers[index].name)")
    }

    /// 타이머 일시정지
    func pauseTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }),
              timers[index].isRunning,
              let endDate = timers[index].endDate else { return }

        let remaining = max(0, Int(endDate.timeIntervalSince(Date())))

        timers[index].remainingSeconds = remaining
        timers[index].isRunning = false
        timers[index].startDate = nil
        timers[index].endDate = nil
        timers[index].pausedDate = Date()

        saveTimers(timers)
        cancelNotification(id: id)
        print("⏸️ 타이머 일시정지: \(timers[index].name), 남은 시간: \(remaining)초")
    }

    /// 타이머 재시작 (완료된 타이머를 처음부터 다시 시작)
    func restartTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        // 남은 시간을 전체 시간으로 리셋
        timers[index].remainingSeconds = timers[index].totalSeconds
        timers[index].isRunning = false
        timers[index].startDate = nil
        timers[index].endDate = nil

        saveTimers(timers)

        // 리셋 후 바로 시작
        startTimer(id: id)
        print("🔄 타이머 재시작: \(timers[index].name)")
    }

    /// 타이머 취소
    func cancelTimer(id: UUID) {
        var timers = timersRelay.value
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }

        let timerName = timers[index].name
        timers.remove(at: index)

        saveTimers(timers)
        cancelNotification(id: id)
        print("❌ 타이머 취소: \(timerName)")
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

        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 사운드 재생
        playTimerSound(for: completedTimer)

        print("✅ 타이머 완료: \(timers[index].name)")
    }

    // MARK: - Persistence

    /// Realm에 저장
    private func saveTimers(_ timers: [TimerItem]) {
        do {
            try RealmManager.performWrite { realm in
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
        } catch {
            print("❌ 타이머 저장 실패: \(error)")
        }

        timersRelay.accept(timers)
    }

    /// Realm에서 로드
    private func loadTimers() {
        let timers: [TimerItem] = RealmManager.performRead { realm in
            let objects = realm.objects(CookingTimerObject.self)
                .sorted(byKeyPath: "createdAt", ascending: false)
            return objects.map { self.timerItem(from: $0) }
        } ?? []

        timersRelay.accept(timers)
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


    /// 앱 시작 시 타이머 복원
    func restoreTimers() {
        var timers = timersRelay.value
        var updated = false

        for i in 0..<timers.count {
            guard timers[i].isRunning,
                  let endDate = timers[i].endDate else { continue }

            let remaining = Int(endDate.timeIntervalSince(Date()))

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
            }
        }

        if updated {
            saveTimers(timers)
        }

        print("🔄 타이머 복원 완료: \(timers.filter { $0.isRunning }.count)개")
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

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 스케줄 실패: \(error)")
            } else {
                print("🔔 알림 스케줄 완료: \(timer.name), 발화 시각: \(endDate)")
            }
        }
    }

    /// 알림 취소
    private func cancelNotification(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_\(id.uuidString)"])
        print("🔕 알림 취소: \(id)")
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
        } else {
            timers[index].remainingSeconds = totalSeconds
            timers[index].startDate = nil
            timers[index].endDate = nil
            cancelNotification(id: timers[index].id)
        }

        saveTimers(timers)
    }
}
