//
//  TimerManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import Foundation
import UIKit
import AudioToolbox
import RealmSwift
import RxSwift
import RxCocoa
import UserNotifications

/// 타이머 관리 싱글톤
final class TimerManager {
    static let shared = TimerManager()

    // MARK: - Properties
    private let realm: Realm
    private var tickTimer: DispatchSourceTimer?
    private let disposeBag = DisposeBag()

    /// 타이머 목록 (RxSwift)
    private let timersRelay = BehaviorRelay<[CookingTimerObject]>(value: [])
    var timers: Driver<[CookingTimerObject]> {
        return timersRelay.asDriver()
    }

    // MARK: - Initialization
    private init() {
        self.realm = try! Realm()
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

            let timers = self.timersRelay.value
            var updated = false

            for timer in timers where timer.state == .running {
                guard let startDate = timer.startDate else { continue }

                let elapsed = Date().timeIntervalSince(startDate)
                let remaining = timer.duration - elapsed

                // 타이머 완료
                if remaining <= 0 {
                    self.completeTimer(id: timer.id)
                    updated = true
                }
            }

            if updated {
                self.loadTimers()
            } else {
                // UI 업데이트를 위해 동일한 배열이라도 갱신 트리거
                self.timersRelay.accept(timers)
            }
        }
    }

    // MARK: - CRUD Operations

    /// 타이머 생성
    func createTimer(title: String, duration: TimeInterval, recipeStepID: String? = nil) {
        let timer = CookingTimerObject(
            title: title,
            duration: duration,
            recipeStepID: recipeStepID
        )

        try? realm.write {
            realm.add(timer)
        }

        loadTimers()
        print("✅ 타이머 생성: \(title), \(duration)초")
    }

    /// 타이머 시작
    func startTimer(id: String) {
        guard let timer = findTimer(id: id) else { return }

        try? realm.write {
            timer.startDate = Date()
            timer.duration = timer.remainingOnPause
            timer.state = .running
        }

        scheduleNotification(for: timer)
        loadTimers()
        print("▶️ 타이머 시작: \(timer.title)")
    }

    /// 타이머 일시정지
    func pauseTimer(id: String) {
        guard let timer = findTimer(id: id),
              timer.state == .running,
              let startDate = timer.startDate else { return }

        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, timer.duration - elapsed)

        try? realm.write {
            timer.remainingOnPause = remaining
            timer.state = .paused
            timer.startDate = nil
        }

        cancelNotification(id: id)
        loadTimers()
        print("⏸️ 타이머 일시정지: \(timer.title), 남은 시간: \(remaining)초")
    }

    /// 타이머 재개
    func resumeTimer(id: String) {
        startTimer(id: id)
    }

    /// 타이머 취소
    func cancelTimer(id: String) {
        guard let timer = findTimer(id: id) else { return }

        try? realm.write {
            realm.delete(timer)
        }

        cancelNotification(id: id)
        loadTimers()
        print("❌ 타이머 취소: \(timer.title)")
    }

    /// 타이머 완료 처리
    private func completeTimer(id: String) {
        guard let timer = findTimer(id: id) else { return }

        try? realm.write {
            timer.state = .done
            timer.startDate = nil
        }

        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 사운드 재생
        playTimerSound()

        loadTimers()
        print("✅ 타이머 완료: \(timer.title)")
    }

    /// 타이머 연장
    func extendTimer(id: String, seconds: TimeInterval) {
        guard let timer = findTimer(id: id) else { return }

        try? realm.write {
            if timer.state == .running {
                timer.duration += seconds
            } else {
                timer.remainingOnPause += seconds
            }
        }

        // 알림 재스케줄
        if timer.state == .running {
            cancelNotification(id: id)
            scheduleNotification(for: timer)
        }

        loadTimers()
        print("⏱️ 타이머 연장: \(timer.title), +\(seconds)초")
    }

    // MARK: - Persistence

    /// Realm에서 타이머 로드
    private func loadTimers() {
        let results = realm.objects(CookingTimerObject.self).sorted(byKeyPath: "createdAt", ascending: false)
        let timers = Array(results)
        timersRelay.accept(timers)
    }

    /// 타이머 검색
    private func findTimer(id: String) -> CookingTimerObject? {
        return realm.object(ofType: CookingTimerObject.self, forPrimaryKey: id)
    }

    /// 앱 시작 시 타이머 복원
    func restoreTimers() {
        let runningTimers = realm.objects(CookingTimerObject.self).filter("state == %@", TimerState.running.rawValue)

        for timer in runningTimers {
            guard let startDate = timer.startDate else { continue }

            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = timer.duration - elapsed

            if remaining <= 0 {
                // 이미 완료된 타이머
                completeTimer(id: timer.id)
            } else {
                // 알림 재스케줄
                scheduleNotification(for: timer)
            }
        }

        loadTimers()
        print("🔄 타이머 복원 완료: \(runningTimers.count)개")
    }

    // MARK: - Notifications

    /// 알림 스케줄
    private func scheduleNotification(for timer: CookingTimerObject) {
        guard let startDate = timer.startDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "타이머 완료"
        content.body = "\(timer.title) 타이머가 종료되었습니다"
        content.sound = getNotificationSound()
        content.categoryIdentifier = "TIMER_CATEGORY"

        let fireDate = startDate.addingTimeInterval(timer.duration)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: timer.id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 스케줄 실패: \(error)")
            } else {
                print("🔔 알림 스케줄 완료: \(timer.title), 발화 시각: \(fireDate)")
            }
        }
    }

    /// 알림 취소
    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("🔕 알림 취소: \(id)")
    }

    /// 모든 실행 중인 타이머의 알림 스케줄 (백그라운드 진입 시)
    func scheduleAllNotifications() {
        let runningTimers = realm.objects(CookingTimerObject.self).filter("state == %@", TimerState.running.rawValue)
        for timer in runningTimers {
            scheduleNotification(for: timer)
        }
    }

    /// 남은 시간 재계산 (포어그라운드 복귀 시)
    func recalculateTimers() {
        // 틱에서 자동으로 재계산됨
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
