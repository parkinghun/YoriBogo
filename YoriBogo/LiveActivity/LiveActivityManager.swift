//
//  LiveActivityManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import Foundation
import ActivityKit

@available(iOS 17.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private init() {}

    private var isEnabled: Bool {
        #if DEBUG
        return ActivityAuthorizationInfo().areActivitiesEnabled
        #else
        return false
        #endif
    }

    func start(for timer: TimerItem) {
        guard isEnabled else { return }

        if hasActivity(for: timer.id.uuidString) {
            update(for: timer)
            return
        }

        let attributes = TimerLiveActivityAttributes(
            timerID: timer.id.uuidString,
            title: timer.name,
            isRecipeStep: timer.recipeStepID != nil
        )

        _ = try? Activity.request(
            attributes: attributes,
            content: makeContent(for: timer),
            pushType: nil
        )
    }

    func update(for timer: TimerItem) {
        guard isEnabled else { return }

        let content = makeContent(for: timer)
        Task {
            for activity in activities(for: timer.id.uuidString) {
                await activity.update(content)
            }
        }
    }

    func end(for timer: TimerItem) {
        Task {
            for activity in activities(for: timer.id.uuidString) {
                await activity.end(makeContent(for: timer), dismissalPolicy: .immediate)
            }
        }
    }

    func endAll() {
        for activity in Activity<TimerLiveActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    func sync(with timers: [TimerItem]) {
        guard isEnabled else {
            endAll()
            return
        }

        let timerByID = Dictionary(uniqueKeysWithValues: timers.map { ($0.id.uuidString, $0) })
        let liveActivities = Activity<TimerLiveActivityAttributes>.activities

        for activity in liveActivities {
            let timerID = activity.attributes.timerID
            guard let timer = timerByID[timerID] else {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
                continue
            }
            // cancel/complete/idle 상태(일시정지가 아님)는 Live Activity를 종료
            if !timer.isRunning, timer.pausedDate == nil {
                Task { await activity.end(makeContent(for: timer), dismissalPolicy: .immediate) }
                continue
            }

            let content = makeContent(for: timer)
            Task { await activity.update(content) }
        }

        // 실행 중 타이머는 Live Activity가 없으면 생성
        for timer in timers where timer.isRunning {
            if !hasActivity(for: timer.id.uuidString) {
                start(for: timer)
            }
        }
    }

    private func hasActivity(for timerID: String) -> Bool {
        return Activity<TimerLiveActivityAttributes>.activities.contains { $0.attributes.timerID == timerID }
    }

    private func activities(for timerID: String) -> [Activity<TimerLiveActivityAttributes>] {
        return Activity<TimerLiveActivityAttributes>.activities.filter { $0.attributes.timerID == timerID }
    }

    private func makeContent(for timer: TimerItem, now: Date = Date()) -> ActivityContent<TimerLiveActivityAttributes.ContentState> {
        let state = TimerLiveActivityAttributes.ContentState(
            endDate: timer.endDate,
            isRunning: timer.isRunning,
            remainingSeconds: max(0, timer.remainingSeconds)
        )

        let staleDate: Date?
        if timer.isRunning {
            staleDate = timer.endDate?.addingTimeInterval(2)
        } else {
            staleDate = now.addingTimeInterval(30)
        }

        return ActivityContent(
            state: state,
            staleDate: staleDate
        )
    }
}
