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

/// 타이머 관리 싱글톤
final class TimerManager {
    static let shared = TimerManager()

    // MARK: - Properties
    private let userDefaultsKey = "cooking_timers"
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

    /// 타이머 생성
    func createTimer(title: String, duration: TimeInterval, recipeStepID: String? = nil) {
        var timers = timersRelay.value
        let timer = TimerItem(
            name: title,
            totalSeconds: Int(duration)
        )
        timers.insert(timer, at: 0)
        saveTimers(timers)
        print("✅ 타이머 생성: \(title), \(Int(duration))초")
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

        timers[index].isRunning = false
        timers[index].remainingSeconds = 0
        timers[index].startDate = nil
        timers[index].endDate = nil

        saveTimers(timers)

        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 사운드 재생
        playTimerSound()

        print("✅ 타이머 완료: \(timers[index].name)")
    }

    // MARK: - Persistence

    /// UserDefaults에 저장
    private func saveTimers(_ timers: [TimerItem]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(timers) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        timersRelay.accept(timers)
    }

    /// UserDefaults에서 로드
    private func loadTimers() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            timersRelay.accept([])
            return
        }

        let decoder = JSONDecoder()
        if let timers = try? decoder.decode([TimerItem].self, from: data) {
            timersRelay.accept(timers)
        } else {
            timersRelay.accept([])
        }
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
        content.sound = getNotificationSound()
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

    /// 남은 시간 재계산 (포어그라운드 복귀 시)
    func recalculateTimers() {
        tick()
    }

    // MARK: - Sound

    /// 알림 사운드 가져오기
    private func getNotificationSound() -> UNNotificationSound {
        let soundName = UserDefaults.standard.string(forKey: "timerSound") ?? "default"
        return soundName == "default" ? .default : UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundName).caf"))
    }

    /// 타이머 완료 사운드 재생
    private func playTimerSound() {
        let soundID = UserDefaults.standard.integer(forKey: "timerSoundID")
        let systemSoundID = soundID > 0 ? SystemSoundID(soundID) : SystemSoundID(1005) // 기본: Alarm
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
