//
//  LiveActivityManager.swift
//  YoriBogo
//
//  Created by Codex on 1/27/26.
//

import Foundation
import ActivityKit

@available(iOS 17.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private init() {}

    func start(for timer: TimerItem) {
        if hasActivity(for: timer.id.uuidString) {
            update(for: timer)
            return
        }

        let attributes = TimerLiveActivityAttributes(
            timerID: timer.id.uuidString,
            title: timer.name,
            isRecipeStep: timer.recipeStepID != nil
        )

        let state = TimerLiveActivityAttributes.ContentState(
            endDate: timer.endDate,
            isRunning: timer.isRunning,
            remainingSeconds: timer.remainingSeconds
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
        } catch {
            print("❌ LiveActivity start failed: \(error)")
        }
    }

    func update(for timer: TimerItem) {
        let state = TimerLiveActivityAttributes.ContentState(
            endDate: timer.endDate,
            isRunning: timer.isRunning,
            remainingSeconds: timer.remainingSeconds
        )
        Task {
            for activity in activities(for: timer.id.uuidString) {
                await activity.update(using: state)
            }
        }
    }

    func end(for timer: TimerItem) {
        Task {
            for activity in activities(for: timer.id.uuidString) {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }

    func endAll() {
        for activity in Activity<TimerLiveActivityAttributes>.activities {
            Task { await activity.end(dismissalPolicy: .immediate) }
        }
    }

    func sync(with timers: [TimerItem]) {
        let timerByID = Dictionary(uniqueKeysWithValues: timers.map { ($0.id.uuidString, $0) })
        let liveActivities = Activity<TimerLiveActivityAttributes>.activities

        for activity in liveActivities {
            let timerID = activity.attributes.timerID
            guard let timer = timerByID[timerID] else {
                Task { await activity.end(dismissalPolicy: .immediate) }
                continue
            }
            // cancel/complete/idle 상태(일시정지가 아님)는 Live Activity를 종료
            if !timer.isRunning, timer.pausedDate == nil {
                Task { await activity.end(dismissalPolicy: .immediate) }
                continue
            }

            let state = TimerLiveActivityAttributes.ContentState(
                endDate: timer.endDate,
                isRunning: timer.isRunning,
                remainingSeconds: timer.remainingSeconds
            )
            Task { await activity.update(using: state) }
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
}
