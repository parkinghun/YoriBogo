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

@available(iOS 17.1, *)
struct PauseResumeTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 정지/재개"
    static let openAppWhenRun = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

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
        let now = Date()
        let previousState = TimerSharedStateStore.state(for: timerID)
            ?? fallbackSharedState(now: now)
        var nextState = previousState

        if requestedAction == "pause" {
            let remainingFromEndDate = nextState.endTime.map { remainingSecondsFromEndDate($0, now: now) }
                ?? nextState.remainingSeconds
            nextState.remainingSeconds = max(0, remainingFromEndDate)
            nextState.isRunning = false
            nextState.startTime = nil
            nextState.endTime = nil
        } else if requestedAction == "resume" {
            var resumedRemaining = max(0, nextState.remainingSeconds)
            if resumedRemaining == 0 {
                resumedRemaining = max(0, remainingSeconds)
            }
            nextState.remainingSeconds = resumedRemaining
            nextState.isRunning = true
            nextState.startTime = now
            nextState.endTime = now.addingTimeInterval(TimeInterval(resumedRemaining))
        } else if nextState.isRunning, let endTime = nextState.endTime {
            let remainingFromEndDate = remainingSecondsFromEndDate(endTime, now: now)
            nextState.remainingSeconds = max(0, remainingFromEndDate)
            nextState.isRunning = false
            nextState.startTime = nil
            nextState.endTime = nil
        } else {
            var resumedRemaining = max(0, nextState.remainingSeconds)
            if resumedRemaining == 0 {
                resumedRemaining = max(0, remainingSeconds)
            }
            nextState.remainingSeconds = resumedRemaining
            nextState.isRunning = true
            nextState.startTime = now
            nextState.endTime = now.addingTimeInterval(TimeInterval(resumedRemaining))
        }

        if nextState.isRunning, let endTime = nextState.endTime {
            let normalizedRemaining = remainingSecondsFromEndDate(endTime, now: now)
            nextState.remainingSeconds = normalizedRemaining
            if normalizedRemaining <= 0 {
                nextState.isRunning = false
                nextState.startTime = nil
                nextState.endTime = nil
            }
        } else {
            nextState.remainingSeconds = max(0, nextState.remainingSeconds)
        }

        nextState.lastUpdatedAt = now
        nextState.version = previousState.version + 1
        nextState.writer = SharedTimerStateWriter.intent

        TimerSharedStateStore.upsert(nextState, makeActive: nextState.isRunning)
        if !nextState.isRunning,
           TimerSharedStateStore.activeTimerID() == nextState.timerID,
           let nextActiveTimerID = pickNextActiveTimerID(excluding: nextState.timerID) {
            TimerSharedStateStore.setActiveTimerID(nextActiveTimerID)
        }

        if nextState.isRunning, let updatedEndDate = nextState.endTime {
            scheduleNotification(timerID: timerID, title: nextState.title, endDate: updatedEndDate)
        } else {
            cancelNotification(timerID: timerID)
        }

        await updateActivity(
            timerID: timerID,
            endDate: nextState.endTime,
            isRunning: nextState.isRunning,
            remainingSeconds: nextState.remainingSeconds
        )

        return .result()
    }

    private func fallbackSharedState(now: Date) -> SharedTimerState {
        let fallbackRemaining = max(0, remainingSeconds)
        let fallbackEndDate = endDateTimestamp > 0
            ? Date(timeIntervalSince1970: endDateTimestamp)
            : now.addingTimeInterval(TimeInterval(fallbackRemaining))

        return SharedTimerState(
            timerID: timerID,
            title: "타이머",
            startTime: isRunning ? now : nil,
            endTime: isRunning ? fallbackEndDate : nil,
            isRunning: isRunning,
            remainingSeconds: fallbackRemaining,
            lastUpdatedAt: now,
            version: 0,
            writer: SharedTimerStateWriter.intent
        )
    }
}

@available(iOS 17.1, *)
struct CancelTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 취소"
    static let openAppWhenRun = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "타이머 ID")
    var timerID: String

    init() {}

    init(timerID: String) {
        self.timerID = timerID
    }

    func perform() async throws -> some IntentResult {
        let now = Date()
        cancelNotification(timerID: timerID)
        await endActivity(timerID: timerID)

        guard var state = TimerSharedStateStore.state(for: timerID) else {
            TimerSharedStateStore.remove(timerID: timerID)
            return .result()
        }

        if state.isRunning, let endTime = state.endTime {
            state.remainingSeconds = remainingSecondsFromEndDate(endTime, now: now)
        }
        state.isRunning = false
        state.startTime = nil
        state.endTime = nil
        state.lastUpdatedAt = now
        state.version += 1
        state.writer = SharedTimerStateWriter.intent

        TimerSharedStateStore.upsert(state)
        if TimerSharedStateStore.activeTimerID() == timerID,
           let nextActiveTimerID = pickNextActiveTimerID(excluding: timerID) {
            TimerSharedStateStore.setActiveTimerID(nextActiveTimerID)
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

private func pickNextActiveTimerID(excluding timerID: String) -> String? {
    let states = TimerSharedStateStore.states()
    if let runningState = states.first(where: { $0.isRunning && $0.timerID != timerID }) {
        return runningState.timerID
    }
    return states.first(where: { $0.timerID != timerID })?.timerID
}

private func cancelNotification(timerID: String) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_\(timerID)"])
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
