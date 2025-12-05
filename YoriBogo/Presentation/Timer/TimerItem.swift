//
//  TimerItem.swift
//  YoriBogo
//
//  Created by 박성훈 on 12/5/25.
//

import Foundation

/// 타이머 아이템 모델
struct TimerItem {
    let id: UUID
    let name: String
    let totalSeconds: Int // 전체 시간 (초)
    var remainingSeconds: Int // 남은 시간 (초)
    var isRunning: Bool // 실행 중 여부

    init(id: UUID = UUID(), name: String, totalSeconds: Int) {
        self.id = id
        self.name = name
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds
        self.isRunning = false
    }

    /// 남은 시간을 "HH:MM:SS" 형식으로 반환
    var remainingTimeString: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// 진행률 (0.0 ~ 1.0)
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    /// 타이머 종료 여부
    var isFinished: Bool {
        return remainingSeconds <= 0
    }
}
