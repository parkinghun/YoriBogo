//
//  TimerLiveActivityWidget.swift
//  YoriBogoWidgets
//
//  Created by 박성훈 on 1/27/26.
//

import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents
import UIKit

@available(iOSApplicationExtension 17.1, *)
struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
            timerLockScreenContent(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    timerExpandedLeadingContent(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    timerExpandedBottomContent(context: context)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.caption2)
                    .frame(width: 16, height: 16, alignment: .center)
            } compactTrailing: {
                timerCompactTrailingContent(context: context)
            } minimal: {
                timerMinimalContent(context: context)
            }
        }
    }
}

@available(iOSApplicationExtension 17.1, *)
private func timerLockScreenContent(
    context: ActivityViewContext<TimerLiveActivityAttributes>
) -> some View {
    let displayState = resolvedDisplayState(for: context)
    return VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.title3)
                .foregroundStyle(Color(uiColor: .brandOrange500))
            Text(context.attributes.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(Color(uiColor: .brandOrange500))
        }

        HStack(spacing: 12) {
            if let endDate = displayState.endDate, displayState.isRunning {
                Text(timerInterval: Date()...endDate, countsDown: true)
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color(uiColor: .brandOrange500))
            } else {
                Text(formatRemainingTime(displayState.remainingSeconds))
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color(uiColor: .brandOrange500))
            }

            Spacer(minLength: 8)

            Button(intent: PauseResumeTimerIntent(
                activityID: context.activityID,
                timerID: context.attributes.timerID,
                isRunning: displayState.isRunning,
                endDateTimestamp: displayState.endDate?.timeIntervalSince1970 ?? 0,
                remainingSeconds: displayState.remainingSeconds,
                requestedAction: displayState.isRunning ? "pause" : "resume"
            )) {
                Image(systemName: displayState.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.plain)
            .background(Circle().fill(Color(uiColor: .brandOrange500)))
            .foregroundStyle(.white)

            Button(intent: CancelTimerIntent(
                activityID: context.activityID,
                timerID: context.attributes.timerID
            )) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.plain)
            .background(Circle().fill(Color(uiColor: .gray600)))
            .foregroundStyle(.white)
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .activityBackgroundTint(.clear)
    .activitySystemActionForegroundColor(.orange)
}

@available(iOSApplicationExtension 17.1, *)
private func timerExpandedLeadingContent(
    context: ActivityViewContext<TimerLiveActivityAttributes>
) -> some View {
    HStack(spacing: 6) {
        Image(systemName: "timer")
            .font(.title3)
            .foregroundStyle(Color(uiColor: .brandOrange500))
        Text(context.attributes.title)
            .font(.headline)
            .lineLimit(1)
            .foregroundStyle(Color(uiColor: UIColor.brandOrange500))
    }
}

@available(iOSApplicationExtension 17.1, *)
private func timerExpandedBottomContent(
    context: ActivityViewContext<TimerLiveActivityAttributes>
) -> some View {
    let displayState = resolvedDisplayState(for: context)
    return HStack(spacing: 12) {
        if let endDate = displayState.endDate, displayState.isRunning {
            Text(timerInterval: Date()...endDate, countsDown: true)
                .font(.system(size: 46, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(uiColor: .brandOrange500))
        } else {
            Text(formatRemainingTime(displayState.remainingSeconds))
                .font(.system(size: 46, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(uiColor: .brandOrange500))
        }
        Spacer(minLength: 8)
        Button(intent: PauseResumeTimerIntent(
            activityID: context.activityID,
            timerID: context.attributes.timerID,
            isRunning: displayState.isRunning,
            endDateTimestamp: displayState.endDate?.timeIntervalSince1970 ?? 0,
            remainingSeconds: displayState.remainingSeconds,
            requestedAction: displayState.isRunning ? "pause" : "resume"
        )) {
            Image(systemName: displayState.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 20, weight: .bold))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .background(Circle().fill(Color(uiColor: .brandOrange500)))
        .foregroundStyle(.white)

        Button(intent: CancelTimerIntent(
            activityID: context.activityID,
            timerID: context.attributes.timerID
        )) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .bold))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .background(Circle().fill(Color(uiColor: .gray600)))
        .foregroundStyle(.white)
    }
}

@available(iOSApplicationExtension 17.1, *)
private func timerCompactTrailingContent(
    context: ActivityViewContext<TimerLiveActivityAttributes>
) -> some View {
    let displayState = resolvedDisplayState(for: context)
    return Group {
        if let endDate = displayState.endDate, displayState.isRunning {
            Text(timerInterval: Date()...endDate, countsDown: true)
                .monospacedDigit()
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 44, alignment: .trailing)
        } else {
            Text(formatRemainingTime(displayState.remainingSeconds))
                .monospacedDigit()
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 44, alignment: .trailing)
        }
    }
}

@available(iOSApplicationExtension 17.1, *)
private func timerMinimalContent(
    context: ActivityViewContext<TimerLiveActivityAttributes>
) -> some View {
    let displayState = resolvedDisplayState(for: context)
    return Group {
        if let endDate = displayState.endDate, displayState.isRunning {
            ProgressView(timerInterval: Date()...endDate, countsDown: true)
                .progressViewStyle(.circular)
        } else {
            ProgressView(value: 0)
                .progressViewStyle(.circular)
        }
    }
}

private struct ResolvedTimerDisplayState {
    var endDate: Date?
    var isRunning: Bool
    var remainingSeconds: Int
}

private func resolvedDisplayState(
    for context: ActivityViewContext<TimerLiveActivityAttributes>,
    now: Date = Date()
) -> ResolvedTimerDisplayState {
    let fallback = ResolvedTimerDisplayState(
        endDate: context.state.endDate,
        isRunning: context.state.isRunning,
        remainingSeconds: max(0, context.state.remainingSeconds)
    )
    guard let shared = TimerSharedStateStore.state(for: context.attributes.timerID) else {
        return fallback
    }

    var isRunning = shared.isRunning
    var endDate = shared.endTime
    var remainingSeconds = max(0, shared.remainingSeconds)

    if isRunning, let runningEndDate = endDate {
        remainingSeconds = max(0, Int(ceil(runningEndDate.timeIntervalSince(now))))
        if remainingSeconds <= 0 {
            isRunning = false
            endDate = nil
        }
    } else if isRunning {
        isRunning = false
        endDate = nil
    } else {
        endDate = nil
    }

    return ResolvedTimerDisplayState(
        endDate: endDate,
        isRunning: isRunning,
        remainingSeconds: remainingSeconds
    )
}

private func formatRemainingTime(_ seconds: Int) -> String {
    let safe = max(0, seconds)
    let hours = safe / 3600
    let minutes = (safe % 3600) / 60
    let secs = safe % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%d:%02d", minutes, secs)
}
