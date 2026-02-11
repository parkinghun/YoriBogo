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

    private var activities: [UUID: Activity<TimerLiveActivityAttributes>] = [:]

    private init() {}

    func start(for timer: TimerItem) {
        guard activities[timer.id] == nil else {
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
            let activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
            activities[timer.id] = activity
        } catch {
            print("❌ LiveActivity start failed: \(error)")
        }
    }

    func update(for timer: TimerItem) {
        guard let activity = activities[timer.id] else { return }
        let state = TimerLiveActivityAttributes.ContentState(
            endDate: timer.endDate,
            isRunning: timer.isRunning,
            remainingSeconds: timer.remainingSeconds
        )
        Task {
            await activity.update(using: state)
        }
    }

    func end(for timer: TimerItem) {
        guard let activity = activities[timer.id] else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        activities.removeValue(forKey: timer.id)
    }

    func endAll() {
        for (_, activity) in activities {
            Task { await activity.end(dismissalPolicy: .immediate) }
        }
        activities.removeAll()
    }
}
