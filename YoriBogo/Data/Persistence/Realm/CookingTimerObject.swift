//
//  CookingTimerObject.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import Foundation
import RealmSwift

/// 타이머 상태
enum TimerState: String, PersistableEnum {
    case running
    case paused
    case done
}

/// 요리 타이머 Realm Object
final class CookingTimerObject: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var title: String
    @Persisted var startDate: Date?
    @Persisted var duration: TimeInterval  // 총 시간 길이 (초 단위)
    @Persisted var remainingOnPause: TimeInterval = 0  // 일시정지 시 남은 시간 (초 단위)
    @Persisted var state: TimerState = .paused
    /// 연결된 레시피 단계 ID (옵셔널)
    @Persisted var recipeStepID: String?
    @Persisted var createdAt: Date = Date()

    convenience init(
        title: String,
        duration: TimeInterval,
        recipeStepID: String? = nil
    ) {
        self.init()
        self.title = title
        self.duration = duration
        self.recipeStepID = recipeStepID
        self.remainingOnPause = duration
    }

    /// 남은 시간 계산 (현재 시각 기준)
    var remainingTime: TimeInterval {
        switch state {
        case .running:
            guard let startDate = startDate else { return 0 }
            let elapsed = Date().timeIntervalSince(startDate)
            return max(0, duration - elapsed)
        case .paused:
            return remainingOnPause
        case .done:
            return 0
        }
    }

    /// 진행률 (0.0 ~ 1.0)
    var progress: Double {
        guard duration > 0 else { return 0 }
        let remaining = remainingTime
        return max(0, min(1, 1 - (remaining / duration)))
    }

    /// 남은 시간 포맷 (MM:SS)
    var formattedRemainingTime: String {
        let remaining = Int(ceil(remainingTime))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 타이머 완료 여부
    var isCompleted: Bool {
        return state == .done || remainingTime <= 0
    }
}
