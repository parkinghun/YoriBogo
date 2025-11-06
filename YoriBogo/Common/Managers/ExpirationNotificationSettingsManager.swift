//
//  ExpirationNotificationSettingsManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 11/2/25.
//

import Foundation

/// 소비기한 알림 설정을 관리하는 매니저
final class ExpirationNotificationSettingsManager {
    static let shared = ExpirationNotificationSettingsManager()

    private let userDefaults = UserDefaults.standard

    // UserDefaults Keys
    private enum Keys {
        static let notificationDays = "expirationNotificationDays"
        static let notificationTime = "expirationNotificationTime"
        static let isFirstLaunch = "isFirstLaunchExpirationNotification"
    }

    private init() {}

    // MARK: - Public Methods

    /// 알림 설정 저장
    /// - Parameters:
    ///   - days: 활성화된 알림 날짜 배열 (소비기한 X일 전)
    ///   - time: 알림 시간
    func saveSettings(days: [Int], time: Date) {
        userDefaults.set(days, forKey: Keys.notificationDays)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        if let hour = components.hour, let minute = components.minute {
            let timeDict = ["hour": hour, "minute": minute]
            userDefaults.set(timeDict, forKey: Keys.notificationTime)
        }

        userDefaults.set(false, forKey: Keys.isFirstLaunch)

        print("✅ ExpirationNotificationSettings 저장 완료")
        print("   알림 날짜: \(days)")
        print("   알림 시간: \(components.hour ?? 0):\(components.minute ?? 0)")
    }

    /// 저장된 알림 날짜 로드
    /// - Returns: 활성화된 알림 날짜 배열 (기본값: [3, 1, 0])
    func loadNotificationDays() -> [Int] {
        if isFirstLaunch() {
            return [3, 1, 0] // 기본값: D-3, D-1, D-Day
        }

        guard let days = userDefaults.array(forKey: Keys.notificationDays) as? [Int] else {
            return [3, 1, 0]
        }

        return days
    }

    /// 저장된 알림 시간 로드
    /// - Returns: 알림 시간 (기본값: 17:00)
    func loadNotificationTime() -> Date {
        if isFirstLaunch() {
            return defaultNotificationTime()
        }

        guard let timeDict = userDefaults.dictionary(forKey: Keys.notificationTime),
              let hour = timeDict["hour"] as? Int,
              let minute = timeDict["minute"] as? Int else {
            return defaultNotificationTime()
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        return Calendar.current.date(from: components) ?? defaultNotificationTime()
    }

    /// 모든 설정 초기화
    func resetSettings() {
        userDefaults.removeObject(forKey: Keys.notificationDays)
        userDefaults.removeObject(forKey: Keys.notificationTime)
        userDefaults.set(true, forKey: Keys.isFirstLaunch)
        print("🗑️ ExpirationNotificationSettings 초기화 완료")
    }

    // MARK: - Private Methods

    /// 첫 실행 여부 확인
    private func isFirstLaunch() -> Bool {
        return !userDefaults.bool(forKey: Keys.isFirstLaunch)
    }

    /// 기본 알림 시간 (17:00)
    private func defaultNotificationTime() -> Date {
        var components = DateComponents()
        components.hour = 17
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
