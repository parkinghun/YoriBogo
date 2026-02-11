//
//  TimerLiveActivityIntents.swift
//  YoriBogoWidgets
//
//  Created by Codex on 1/27/26.
//

import Foundation
import AppIntents
import ActivityKit
import UserNotifications
import RealmSwift

@available(iOS 17.1, *)
struct PauseResumeTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "타이머 정지/재개"

    @Parameter(title: "타이머 ID")
    var timerID: String
    @Parameter(title: "실행 중 여부")
    var isRunning: Bool
    @Parameter(title: "종료 시각 (타임스탬프)")
    var endDateTimestamp: Double
    @Parameter(title: "남은 시간 (초)")
    var remainingSeconds: Int

    init() {}

    init(timerID: String, isRunning: Bool, endDateTimestamp: Double, remainingSeconds: Int) {
        self.timerID = timerID
        self.isRunning = isRunning
        self.endDateTimestamp = endDateTimestamp
        self.remainingSeconds = remainingSeconds
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else { return .result() }
        let now = Date()
        let running = isRunning
        let endDate = endDateTimestamp > 0 ? Date(timeIntervalSince1970: endDateTimestamp) : nil
        let activityCount = Activity<TimerLiveActivityAttributes>.activities.filter { $0.attributes.timerID == timerID }.count
        logIntent(
            name: "PauseResume",
            timerID: timerID,
            payload: [
                "isRunning": "\(running)",
                "endDate": endDate?.description ?? "nil",
                "remainingSeconds": "\(remainingSeconds)",
                "activityCount": "\(activityCount)"
            ]
        )

        var updatedRemaining = max(0, remainingSeconds)
        var updatedEndDate: Date?
        var updatedIsRunning: Bool

        if running, let endDate {
            updatedRemaining = max(0, Int(endDate.timeIntervalSince(now)))
            updatedIsRunning = false
            updatedEndDate = nil
            cancelNotification(id: uuid)
        } else {
            updatedIsRunning = true
            updatedEndDate = now.addingTimeInterval(TimeInterval(updatedRemaining))
        }

        await updateActivity(
            timerID: timerID,
            endDate: updatedEndDate,
            isRunning: updatedIsRunning,
            remainingSeconds: updatedRemaining
        )
        logIntent(
            name: "PauseResumeUpdated",
            timerID: timerID,
            payload: [
                "updatedIsRunning": "\(updatedIsRunning)",
                "updatedEndDate": updatedEndDate?.description ?? "nil",
                "updatedRemaining": "\(updatedRemaining)"
            ]
        )

        do {
            let realm = try TimerRealmStore.realm()
            if let object = realm.object(ofType: CookingTimerObject.self, forPrimaryKey: uuid.uuidString) {
                try realm.write {
                    object.remainingSeconds = updatedRemaining
                    object.isRunning = updatedIsRunning
                    object.startDate = updatedIsRunning ? now : nil
                    object.endDate = updatedEndDate
                    object.pausedDate = updatedIsRunning ? nil : now
                }
                if updatedIsRunning, let updatedEndDate {
                    scheduleNotification(for: object, endDate: updatedEndDate)
                }
            }
        } catch {
            // Ignore realm errors; live activity state already updated.
        }

        return .result()
    }
}

@available(iOS 17.1, *)
struct CancelTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "타이머 취소"

    @Parameter(title: "타이머 ID")
    var timerID: String

    init() {}

    init(timerID: String) {
        self.timerID = timerID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else { return .result() }
        let activityCount = Activity<TimerLiveActivityAttributes>.activities.filter { $0.attributes.timerID == timerID }.count
        logIntent(
            name: "Cancel",
            timerID: timerID,
            payload: [
                "activityCount": "\(activityCount)"
            ]
        )
        cancelNotification(id: uuid)
        await endActivity(timerID: timerID)
        logIntent(name: "CancelEnded", timerID: timerID, payload: [:])
        do {
            let realm = try TimerRealmStore.realm()
            if let object = realm.object(ofType: CookingTimerObject.self, forPrimaryKey: uuid.uuidString) {
                try realm.write {
                    realm.delete(object)
                }
            }
        } catch {
            // Ignore realm errors; live activity already ended.
        }
        return .result()
    }
}

@available(iOS 17.1, *)
private func updateActivity(timerID: String, endDate: Date?, isRunning: Bool, remainingSeconds: Int) async {
    for activity in Activity<TimerLiveActivityAttributes>.activities where activity.attributes.timerID == timerID {
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
    for activity in Activity<TimerLiveActivityAttributes>.activities where activity.attributes.timerID == timerID {
        await activity.end(dismissalPolicy: .immediate)
    }
}

private func cancelNotification(id: UUID) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_\(id.uuidString)"])
}

private func scheduleNotification(for timer: CookingTimerObject, endDate: Date) {
    let content = UNMutableNotificationContent()
    content.title = "\(timer.title) 타이머 완료!"
    content.body = "타이머가 종료되었습니다"
    content.sound = .default

    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: endDate
    )

    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
        identifier: "timer_\(timer.id)",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

private func logIntent(name: String, timerID: String, payload: [String: String]) {
    guard let defaults = UserDefaults(suiteName: TimerRealmStore.appGroupID) else { return }
    let timestamp = Date().timeIntervalSince1970
    var data = payload
    data["timestamp"] = "\(timestamp)"
    data["name"] = name
    data["timerID"] = timerID
    defaults.set(data, forKey: "LiveActivityLastIntent")
    print("🟨 LiveActivityIntent:", data)
}
