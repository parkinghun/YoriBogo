//
//  TimerSettings.swift
//  YoriBogo
//
//  Created by Codex on 1/27/26.
//

import Foundation

struct TimerSoundOption: Equatable {
    let id: String
    let title: String
    let systemSoundID: Int
}

struct TimerSettings {
    static let timerSoundKey = "timerSound"
    static let timerSoundIDKey = "timerSoundID"
    static let defaultTimerDurationKey = "defaultTimerDuration"

    static let defaultDurationSeconds = 300

    static let soundOptions: [TimerSoundOption] = [
        TimerSoundOption(id: "default", title: "기본", systemSoundID: 1005),
        TimerSoundOption(id: "bell", title: "벨", systemSoundID: 1007),
        TimerSoundOption(id: "chime", title: "차임", systemSoundID: 1008),
        TimerSoundOption(id: "alert", title: "경고음", systemSoundID: 1009)
    ]

    static func selectedSoundOption() -> TimerSoundOption {
        let savedID = UserDefaults.standard.string(forKey: timerSoundKey)
        if let savedID, let option = soundOptions.first(where: { $0.id == savedID }) {
            return option
        }
        return soundOptions.first ?? TimerSoundOption(id: "default", title: "기본", systemSoundID: 1005)
    }

    static func saveSound(_ option: TimerSoundOption) {
        UserDefaults.standard.set(option.id, forKey: timerSoundKey)
        UserDefaults.standard.set(option.systemSoundID, forKey: timerSoundIDKey)
    }

    static func selectedSoundTitle() -> String {
        return selectedSoundOption().title
    }

    static func title(for id: String) -> String {
        return soundOptions.first(where: { $0.id == id })?.title ?? selectedSoundTitle()
    }

    static func option(for id: String) -> TimerSoundOption {
        return soundOptions.first(where: { $0.id == id }) ?? selectedSoundOption()
    }

    static func defaultDuration() -> Int {
        if UserDefaults.standard.object(forKey: defaultTimerDurationKey) == nil {
            return defaultDurationSeconds
        }
        return UserDefaults.standard.integer(forKey: defaultTimerDurationKey)
    }

    static func saveDefaultDuration(seconds: Int) {
        let clamped = max(0, seconds)
        UserDefaults.standard.set(clamped, forKey: defaultTimerDurationKey)
    }

    static func split(seconds: Int) -> (hours: Int, minutes: Int, seconds: Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return (hours, minutes, secs)
    }

    static func formatDuration(seconds: Int) -> String {
        let parts = split(seconds: max(0, seconds))
        if parts.hours > 0 {
            return String(format: "%d:%02d:%02d", parts.hours, parts.minutes, parts.seconds)
        }
        return String(format: "%d:%02d", parts.minutes, parts.seconds)
    }
}
