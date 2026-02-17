//
//  TimerLiveActivityAttributes.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import Foundation
import ActivityKit

@available(iOS 17.1, *)
struct TimerLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endDate: Date?
        var isRunning: Bool
        var remainingSeconds: Int
    }

    var timerID: String
    var title: String
    var isRecipeStep: Bool
}
