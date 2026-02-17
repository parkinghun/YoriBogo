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
            VStack(alignment: .leading, spacing: 12) {
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
                    if let endDate = context.state.endDate, context.state.isRunning {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color(uiColor: .brandOrange500))
                    } else {
                        Text(formatRemainingTime(context.state.remainingSeconds))
                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color(uiColor: .brandOrange500))
                    }

                    Spacer(minLength: 8)

                    Button(intent: PauseResumeTimerIntent(
                        timerID: context.attributes.timerID,
                        isRunning: context.state.isRunning,
                        endDateTimestamp: context.state.endDate?.timeIntervalSince1970 ?? 0,
                        remainingSeconds: context.state.remainingSeconds,
                        requestedAction: context.state.isRunning ? "pause" : "resume"
                    )) {
                        Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 50, height: 50)
                    }
                    .buttonStyle(.plain)
                    .background(Circle().fill(Color(uiColor: .brandOrange500)))
                    .foregroundStyle(.white)

                    Button(intent: CancelTimerIntent(timerID: context.attributes.timerID)) {
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
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
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
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        if let endDate = context.state.endDate, context.state.isRunning {
                            Text(timerInterval: Date()...endDate, countsDown: true)
                                .font(.system(size: 46, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color(uiColor: .brandOrange500))
                        } else {
                            Text(formatRemainingTime(context.state.remainingSeconds))
                                .font(.system(size: 46, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color(uiColor: .brandOrange500))
                        }
                        Spacer(minLength: 8)
                        Button(intent: PauseResumeTimerIntent(
                            timerID: context.attributes.timerID,
                            isRunning: context.state.isRunning,
                            endDateTimestamp: context.state.endDate?.timeIntervalSince1970 ?? 0,
                            remainingSeconds: context.state.remainingSeconds,
                            requestedAction: context.state.isRunning ? "pause" : "resume"
                        )) {
                            Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.plain)
                        .background(Circle().fill(Color(uiColor: .brandOrange500)))
                        .foregroundStyle(.white)

                        Button(intent: CancelTimerIntent(timerID: context.attributes.timerID)) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.plain)
                        .background(Circle().fill(Color(uiColor: .gray600)))
                        .foregroundStyle(.white)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.caption2)
                    .frame(width: 16, height: 16, alignment: .center)
            } compactTrailing: {
                if let endDate = context.state.endDate, context.state.isRunning {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: 44, alignment: .trailing)
                } else {
                    Text(formatRemainingTime(context.state.remainingSeconds))
                        .monospacedDigit()
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: 44, alignment: .trailing)
                }
            } minimal: {
                if let endDate = context.state.endDate, context.state.isRunning {
                    ProgressView(timerInterval: Date()...endDate, countsDown: true)
                        .progressViewStyle(.circular)
                } else {
                    ProgressView(value: 0)
                        .progressViewStyle(.circular)
                }
            }
        }
    }
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
