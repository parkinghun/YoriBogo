//
//  TimerLiveActivityIntents.swift
//  YoriBogoWidgets
//
//  Created by 박성훈 on 1/27/26.
//

import Foundation
import AppIntents
import ActivityKit
import UserNotifications
import RealmSwift

@available(iOS 17.1, *)
struct PauseResumeTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 정지/재개"
    static let openAppWhenRun = false

    @Parameter(title: "타이머 ID")
    var timerID: String
    @Parameter(title: "실행 중 여부")
    var isRunning: Bool
    @Parameter(title: "종료 시각 (타임스탬프)")
    var endDateTimestamp: Double
    @Parameter(title: "남은 시간 (초)")
    var remainingSeconds: Int
    @Parameter(title: "요청 액션")
    var requestedAction: String

    init() {}

    init(timerID: String, isRunning: Bool, endDateTimestamp: Double, remainingSeconds: Int, requestedAction: String) {
        self.timerID = timerID
        self.isRunning = isRunning
        self.endDateTimestamp = endDateTimestamp
        self.remainingSeconds = remainingSeconds
        self.requestedAction = requestedAction
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else { return .result() }
        let now = Date()
        var running = false
        var endDate: Date?
        var currentRemaining = 0

        var updatedRemaining = 0
        var updatedEndDate: Date?
        var updatedIsRunning = false
        var timerTitle = "타이머"

        do {
            let realm = try TimerRealmStore.realm()
            guard let object = realm.object(ofType: CookingTimerObject.self, forPrimaryKey: uuid.uuidString) else {
                await endActivity(timerID: timerID)
                return .result()
            }

            timerTitle = object.title
            running = object.isRunning
            endDate = object.endDate
            currentRemaining = object.remainingSeconds

            try realm.write {
                if requestedAction == "pause" {
                    let remainingFromEndDate = endDate.map { remainingSecondsFromEndDate($0, now: now) } ?? currentRemaining
                    updatedRemaining = max(0, remainingFromEndDate)
                    updatedIsRunning = false
                    updatedEndDate = nil
                    object.remainingSeconds = updatedRemaining
                    object.isRunning = false
                    object.startDate = nil
                    object.endDate = nil
                    object.pausedDate = now
                } else if requestedAction == "resume" {
                    updatedRemaining = max(0, object.remainingSeconds)
                    if updatedRemaining == 0 {
                        updatedRemaining = object.totalSeconds
                    }
                    updatedIsRunning = true
                    updatedEndDate = now.addingTimeInterval(TimeInterval(updatedRemaining))
                    object.remainingSeconds = updatedRemaining
                    object.isRunning = true
                    object.startDate = now
                    object.endDate = updatedEndDate
                    object.pausedDate = nil
                } else if running, let endDate {
                    updatedRemaining = remainingSecondsFromEndDate(endDate, now: now)
                    updatedIsRunning = false
                    updatedEndDate = nil
                    object.remainingSeconds = updatedRemaining
                    object.isRunning = false
                    object.startDate = nil
                    object.endDate = nil
                    object.pausedDate = now
                } else {
                    updatedRemaining = max(0, object.remainingSeconds)
                    if updatedRemaining == 0 {
                        updatedRemaining = object.totalSeconds
                    }
                    updatedIsRunning = true
                    updatedEndDate = now.addingTimeInterval(TimeInterval(updatedRemaining))
                    object.remainingSeconds = updatedRemaining
                    object.isRunning = true
                    object.startDate = now
                    object.endDate = updatedEndDate
                    object.pausedDate = nil
                }
            }
        } catch {
            return .result()
        }

        if updatedIsRunning, let updatedEndDate {
            scheduleNotification(timerID: uuid.uuidString, title: timerTitle, endDate: updatedEndDate)
        } else {
            cancelNotification(id: uuid)
        }

        await updateActivity(
            timerID: timerID,
            endDate: updatedEndDate,
            isRunning: updatedIsRunning,
            remainingSeconds: updatedRemaining
        )

        return .result()
    }
}

@available(iOS 17.1, *)
struct CancelTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 취소"
    static let openAppWhenRun = false

    @Parameter(title: "타이머 ID")
    var timerID: String

    init() {}

    init(timerID: String) {
        self.timerID = timerID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else { return .result() }
        cancelNotification(id: uuid)
        await endActivity(timerID: timerID)
        do {
            let realm = try TimerRealmStore.realm()
            if let object = realm.object(ofType: CookingTimerObject.self, forPrimaryKey: uuid.uuidString) {
                try realm.write {
                    object.remainingSeconds = object.totalSeconds
                    object.isRunning = false
                    object.startDate = nil
                    object.endDate = nil
                    object.pausedDate = nil
                }
            }
        } catch {
        }
        return .result()
    }
}

@available(iOS 17.1, *)
private func updateActivity(timerID: String, endDate: Date?, isRunning: Bool, remainingSeconds: Int) async {
    let targets = Activity<TimerLiveActivityAttributes>.activities.filter { $0.attributes.timerID == timerID }
    for activity in targets {
        let state = TimerLiveActivityAttributes.ContentState(
            endDate: endDate,
            isRunning: isRunning,
            remainingSeconds: max(0, remainingSeconds)
        )
        await activity.update(using: state)
    }
}

@available(iOS 17.1, *)
private func endActivity(timerID: String) async {
    let targets = Activity<TimerLiveActivityAttributes>.activities.filter { $0.attributes.timerID == timerID }
    for activity in targets {
        await activity.end(dismissalPolicy: .immediate)
    }
}

private func cancelNotification(id: UUID) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_\(id.uuidString)"])
}

private func scheduleNotification(timerID: String, title: String, endDate: Date) {
    let content = UNMutableNotificationContent()
    content.title = "\(title) 타이머 완료!"
    content.body = "타이머가 종료되었습니다"
    content.sound = .default

    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: endDate
    )

    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
        identifier: "timer_\(timerID)",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

private func remainingSecondsFromEndDate(_ endDate: Date, now: Date = Date()) -> Int {
    max(0, Int(ceil(endDate.timeIntervalSince(now))))
}
