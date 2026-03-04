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

private let intentMutationLock = NSLock()

private func withIntentMutationLock<T>(_ block: () -> T) -> T {
    intentMutationLock.lock()
    defer { intentMutationLock.unlock() }
    return block()
}

private enum TimerControlAction {
    case pause
    case resume
    case toggle

    init(requestedAction: String) {
        switch requestedAction.lowercased() {
        case "pause":
            self = .pause
        case "resume":
            self = .resume
        default:
            self = .toggle
        }
    }
}

private struct IntentMutationResult {
    var state: SharedTimerState
}

@available(iOS 17.1, *)
struct PauseResumeTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 정지/재개"
    static let openAppWhenRun = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "라이브 액티비티 ID")
    var activityID: String
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

    init(activityID: String, timerID: String, isRunning: Bool, endDateTimestamp: Double, remainingSeconds: Int, requestedAction: String) {
        self.activityID = activityID
        self.timerID = timerID
        self.isRunning = isRunning
        self.endDateTimestamp = endDateTimestamp
        self.remainingSeconds = remainingSeconds
        self.requestedAction = requestedAction
    }

    func perform() async throws -> some IntentResult {
        let now = Date()
        let mutation = withIntentMutationLock {
            let storedState = TimerSharedStateStore.state(for: timerID)
            let previousState = storedState ?? fallbackSharedState(now: now)
            var nextState = normalizedSharedState(previousState, now: now)
            let didNormalize = nextState != previousState

            let action = TimerControlAction(requestedAction: requestedAction)
            let didApplyAction = apply(action, to: &nextState, now: now, fallbackRemainingSeconds: remainingSeconds)
            nextState = normalizedSharedState(nextState, now: now)

            let didMutate = didNormalize || didApplyAction
            guard didMutate else {
                return IntentMutationResult(state: nextState)
            }

            let latestVersion = TimerSharedStateStore.state(for: timerID)?.version ?? nextState.version
            nextState.lastUpdatedAt = now
            nextState.version = max(latestVersion, nextState.version) + 1
            nextState.writer = SharedTimerStateWriter.intent

            TimerSharedStateStore.upsert(nextState, makeActive: nextState.isRunning)
            if !nextState.isRunning,
               TimerSharedStateStore.activeTimerID() == nextState.timerID,
               let nextActiveTimerID = pickNextActiveTimerID(excluding: nextState.timerID) {
                TimerSharedStateStore.setActiveTimerID(nextActiveTimerID)
            }

            let committed = TimerSharedStateStore.state(for: timerID) ?? nextState
            return IntentMutationResult(state: committed)
        }

        if mutation.state.isRunning, let updatedEndDate = mutation.state.endTime {
            scheduleNotification(timerID: timerID, title: mutation.state.title, endDate: updatedEndDate)
        } else {
            cancelNotification(timerID: timerID)
        }

        await updateActivity(
            activityID: activityID,
            timerID: timerID,
            state: mutation.state
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

    @Parameter(title: "라이브 액티비티 ID")
    var activityID: String
    @Parameter(title: "타이머 ID")
    var timerID: String

    init() {}

    init(activityID: String, timerID: String) {
        self.activityID = activityID
        self.timerID = timerID
    }

    func perform() async throws -> some IntentResult {
        let now = Date()
        let mutation = withIntentMutationLock {
            let storedState = TimerSharedStateStore.state(for: timerID)
            var nextState = storedState ?? SharedTimerState(
                timerID: timerID,
                title: "타이머",
                startTime: nil,
                endTime: nil,
                isRunning: false,
                remainingSeconds: 0,
                lastUpdatedAt: now,
                version: 0,
                writer: SharedTimerStateWriter.intent
            )
            nextState = normalizedSharedState(nextState, now: now)
            let previousState = nextState

            if nextState.isRunning, let endTime = nextState.endTime {
                nextState.remainingSeconds = remainingSecondsFromEndDate(endTime, now: now)
            }
            nextState.isRunning = false
            nextState.startTime = nil
            nextState.endTime = nil

            let didMutate = nextState != previousState
            guard didMutate else {
                return IntentMutationResult(state: nextState)
            }

            let latestVersion = TimerSharedStateStore.state(for: timerID)?.version ?? nextState.version
            nextState.lastUpdatedAt = now
            nextState.version = max(latestVersion, nextState.version) + 1
            nextState.writer = SharedTimerStateWriter.intent

            TimerSharedStateStore.upsert(nextState)
            if TimerSharedStateStore.activeTimerID() == timerID,
               let nextActiveTimerID = pickNextActiveTimerID(excluding: timerID) {
                TimerSharedStateStore.setActiveTimerID(nextActiveTimerID)
            }

            let committed = TimerSharedStateStore.state(for: timerID) ?? nextState
            return IntentMutationResult(state: committed)
        }

        cancelNotification(timerID: timerID)
        await updateActivity(activityID: activityID, timerID: timerID, state: mutation.state)
        await endActivity(activityID: activityID, timerID: timerID)

        return .result()
    }
}

@available(iOS 17.1, *)
private func updateActivity(activityID: String, timerID: String, state: SharedTimerState) async {
    let targets = targetActivities(activityID: activityID, timerID: timerID)
    for activity in targets {
        let contentState = TimerLiveActivityAttributes.ContentState(
            endDate: state.endTime,
            isRunning: state.isRunning,
            remainingSeconds: max(0, state.remainingSeconds)
        )
        let content = ActivityContent(
            state: contentState,
            staleDate: state.isRunning ? state.endTime?.addingTimeInterval(2) : Date().addingTimeInterval(30)
        )
        await activity.update(content)
    }
}

@available(iOS 17.1, *)
private func endActivity(activityID: String, timerID: String) async {
    let targets = targetActivities(activityID: activityID, timerID: timerID)
    for activity in targets {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}

@available(iOS 17.1, *)
private func targetActivities(activityID: String, timerID: String) -> [Activity<TimerLiveActivityAttributes>] {
    if !activityID.isEmpty {
        let byActivityID = Activity<TimerLiveActivityAttributes>.activities.filter { $0.id == activityID }
        if !byActivityID.isEmpty {
            return byActivityID
        }
    }
    return Activity<TimerLiveActivityAttributes>.activities.filter { $0.attributes.timerID == timerID }
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

private func normalizedSharedState(_ state: SharedTimerState, now: Date) -> SharedTimerState {
    var nextState = state
    nextState.remainingSeconds = max(0, nextState.remainingSeconds)

    if nextState.isRunning {
        guard let endTime = nextState.endTime else {
            nextState.isRunning = false
            nextState.startTime = nil
            return nextState
        }
        let remaining = remainingSecondsFromEndDate(endTime, now: now)
        nextState.remainingSeconds = remaining
        if remaining <= 0 {
            nextState.isRunning = false
            nextState.startTime = nil
            nextState.endTime = nil
        }
    } else {
        nextState.startTime = nil
        nextState.endTime = nil
    }

    return nextState
}

private func apply(
    _ action: TimerControlAction,
    to state: inout SharedTimerState,
    now: Date,
    fallbackRemainingSeconds: Int
) -> Bool {
    switch action {
    case .pause:
        guard state.isRunning else { return false }
        if let endTime = state.endTime {
            state.remainingSeconds = remainingSecondsFromEndDate(endTime, now: now)
        } else {
            state.remainingSeconds = max(0, state.remainingSeconds)
        }
        state.isRunning = false
        state.startTime = nil
        state.endTime = nil
        return true

    case .resume:
        guard !state.isRunning else { return false }
        var resumedRemaining = max(0, state.remainingSeconds)
        if resumedRemaining == 0 {
            resumedRemaining = max(0, fallbackRemainingSeconds)
        }
        guard resumedRemaining > 0 else { return false }

        state.remainingSeconds = resumedRemaining
        state.isRunning = true
        state.startTime = now
        state.endTime = now.addingTimeInterval(TimeInterval(resumedRemaining))
        return true

    case .toggle:
        let resolvedAction: TimerControlAction = state.isRunning ? .pause : .resume
        return apply(
            resolvedAction,
            to: &state,
            now: now,
            fallbackRemainingSeconds: fallbackRemainingSeconds
        )
    }
}
