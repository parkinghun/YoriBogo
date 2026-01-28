//
//  TimerLiveActivityWidget.swift
//  YoriBogoWidgets
//
//  Created by Codex on 1/27/26.
//

import WidgetKit
import SwiftUI
import ActivityKit

@available(iOSApplicationExtension 17.1, *)
struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(context.attributes.isRecipeStep ? "레시피 단계 타이머" : "타이머")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let endDate = context.state.endDate, context.state.isRunning {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                        .font(.title3)
                } else {
                    Text("일시 정지")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let endDate = context.state.endDate, context.state.isRunning {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .monospacedDigit()
                    } else {
                        Text("정지")
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                if let endDate = context.state.endDate, context.state.isRunning {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                } else {
                    Text("정지")
                }
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
