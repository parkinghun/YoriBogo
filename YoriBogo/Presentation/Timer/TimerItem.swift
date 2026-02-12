//
//  TimerItem.swift
//  YoriBogo
//
//  Created by 박성훈 on 12/5/25.
//

import Foundation

/// 타이머 아이템 모델
struct TimerItem: Codable {
    let id: UUID
    var name: String
    var totalSeconds: Int // 전체 시간 (초)
    var remainingSeconds: Int // 남은 시간 (초)
    var isRunning: Bool // 실행 중 여부
    var startDate: Date? // 타이머 시작 시간
    var endDate: Date? // 타이머 종료 예정 시간
    var pausedDate: Date? // 일시정지된 시간
    var soundID: String // 알림음 ID
    var soundSystemSoundID: Int // 완료 사운드 ID
    var recipeStepID: String? // 레시피 단계 ID
    var createdAt: Date // 생성 시각

    init(
        id: UUID = UUID(),
        name: String,
        totalSeconds: Int,
        recipeStepID: String? = nil,
        createdAt: Date = Date(),
        soundID: String? = nil,
        soundSystemSoundID: Int? = nil
    ) {
        let defaultSound = TimerSettings.selectedSoundOption()
        self.id = id
        self.name = name
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds
        self.isRunning = false
        self.startDate = nil
        self.endDate = nil
        self.pausedDate = nil
        self.soundID = soundID ?? defaultSound.id
        self.soundSystemSoundID = soundSystemSoundID ?? defaultSound.systemSoundID
        self.recipeStepID = recipeStepID
        self.createdAt = createdAt
    }

    /// 현재 시간 기준 남은 시간 계산
    mutating func updateRemainingTime() {
        guard isRunning, let endDate = endDate else { return }

        let remaining = Int(ceil(endDate.timeIntervalSince(Date())))
        remainingSeconds = max(0, remaining)
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

    /// 전체 시간을 "HH:MM:SS" 형식으로 반환
    var totalTimeString: String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// 타이머 종료 여부
    var isFinished: Bool {
        return remainingSeconds <= 0
    }

    var soundTitle: String {
        return TimerSettings.title(for: soundID)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case totalSeconds
        case remainingSeconds
        case isRunning
        case startDate
        case endDate
        case pausedDate
        case soundID
        case soundSystemSoundID
        case recipeStepID
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultSound = TimerSettings.selectedSoundOption()

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        totalSeconds = try container.decode(Int.self, forKey: .totalSeconds)
        remainingSeconds = try container.decode(Int.self, forKey: .remainingSeconds)
        isRunning = try container.decode(Bool.self, forKey: .isRunning)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        pausedDate = try container.decodeIfPresent(Date.self, forKey: .pausedDate)
        soundID = try container.decodeIfPresent(String.self, forKey: .soundID) ?? defaultSound.id
        soundSystemSoundID = try container.decodeIfPresent(Int.self, forKey: .soundSystemSoundID) ?? defaultSound.systemSoundID
        recipeStepID = try container.decodeIfPresent(String.self, forKey: .recipeStepID)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(totalSeconds, forKey: .totalSeconds)
        try container.encode(remainingSeconds, forKey: .remainingSeconds)
        try container.encode(isRunning, forKey: .isRunning)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(pausedDate, forKey: .pausedDate)
        try container.encode(soundID, forKey: .soundID)
        try container.encode(soundSystemSoundID, forKey: .soundSystemSoundID)
        try container.encodeIfPresent(recipeStepID, forKey: .recipeStepID)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
