//
//  NotificationService.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-26.
//

import Foundation
import UserNotifications
import FirebaseMessaging

/// 소비기한 알림을 관리하는 서비스
final class NotificationService {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// 알림 권한 요청
    /// - Parameter completion: 권한 허용 여부 콜백
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ NotificationService: 권한 요청 실패 - \(error.localizedDescription)")
                    completion?(false)
                    return
                }

                if granted {
                    print("✅ NotificationService: 알림 권한 허용됨")
                    // Analytics 로깅: 권한 허용
                    AnalyticsService.shared.logPushPermissionGranted()
                    AnalyticsService.shared.setUserProperty(key: "push_permission", value: "granted")
                } else {
                    print("⚠️ NotificationService: 알림 권한 거부됨")
                    // Analytics 로깅: 권한 거부
                    AnalyticsService.shared.logPushPermissionDenied()
                    AnalyticsService.shared.setUserProperty(key: "push_permission", value: "denied")
                }

                completion?(granted)
            }
        }
    }

    /// 현재 알림 권한 상태 확인
    /// - Parameter completion: 권한 상태 콜백
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - 알림 등록/삭제

    /// 알림 요청 등록
    /// - Parameters:
    ///   - request: UNNotificationRequest
    ///   - completion: 성공/실패 콜백
    func addNotificationRequest(_ request: UNNotificationRequest, completion: ((Error?) -> Void)? = nil) {
        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ NotificationService: 알림 등록 실패 [\(request.identifier)] - \(error.localizedDescription)")
                } else {
                    print("✅ NotificationService: 알림 등록 성공 [\(request.identifier)]")
                }
                completion?(error)
            }
        }
    }

    /// 특정 식별자의 알림 삭제
    /// - Parameter identifiers: 삭제할 알림 식별자 배열
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ NotificationService: 알림 삭제됨 - \(identifiers)")
    }

    /// 모든 알림 삭제
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🗑️ NotificationService: 모든 알림 삭제됨")
    }

    // MARK: - 디버깅

    /// 현재 등록된 알림 목록 출력 (디버그용)
    func printPendingNotifications() {
        center.getPendingNotificationRequests { requests in
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📋 등록된 알림 개수: \(requests.count)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            if requests.isEmpty {
                print("  (등록된 알림 없음)")
            } else {
                for (index, request) in requests.enumerated() {
                    print("\n[\(index + 1)] Identifier: \(request.identifier)")
                    print("  Title: \(request.content.title)")
                    print("  Body: \(request.content.body)")

                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        let components = trigger.dateComponents
                        print("  Trigger: \(components.year ?? 0)/\(components.month ?? 0)/\(components.day ?? 0) \(components.hour ?? 0):\(components.minute ?? 0)")
                    }
                }
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }

    /// 특정 식별자의 알림 존재 여부 확인
    /// - Parameters:
    ///   - identifier: 확인할 알림 식별자
    ///   - completion: 존재 여부 콜백
    func hasNotification(withIdentifier identifier: String, completion: @escaping (Bool) -> Void) {
        center.getPendingNotificationRequests { requests in
            let exists = requests.contains { $0.identifier == identifier }
            DispatchQueue.main.async {
                completion(exists)
            }
        }
    }

    // MARK: - 테스트용 알림

    /// 테스트용 알림 전송 (5초, 10초, 15초 후 발송)
    func scheduleTestNotifications() {
        print("\n🧪 [TEST] 테스트 알림 스케줄링 시작")

        let testNotifications: [(seconds: TimeInterval, title: String, body: String)] = [
            (5, "🧪 테스트 D-3 알림", "'당근'의 소비기한이 3일 남았어요."),
            (10, "🧪 테스트 D-1 알림", "'양파'의 소비기한이 하루 남았어요!"),
            (15, "🧪 테스트 D-Day 알림", "오늘 '감자'의 소비기한이에요. 냉장고를 확인하세요!")
        ]

        for (index, notification) in testNotifications.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            content.badge = NSNumber(value: index + 1)

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notification.seconds, repeats: false)
            let identifier = "test_notification_\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            addNotificationRequest(request) { error in
                if error == nil {
                    print("   ✅ [\(Int(notification.seconds))초 후] \(notification.title)")
                }
            }
        }

        print("🧪 [TEST] 테스트 알림 3개 스케줄링 완료\n")

        // Analytics 로깅: 테스트 알림 스케줄 등록
        AnalyticsService.shared.logNotificationScheduled(
            notificationType: "test",
            count: testNotifications.count
        )
    }

    /// 테스트 알림 모두 삭제
    func removeTestNotifications() {
        let identifiers = (0..<3).map { "test_notification_\($0)" }
        removePendingNotifications(withIdentifiers: identifiers)
        print("🗑️ [TEST] 테스트 알림 삭제 완료")
    }

    // MARK: - 뱃지 관리

    /// 앱 아이콘 뱃지 초기화
    func clearBadge() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("❌ NotificationService: 뱃지 초기화 실패 - \(error.localizedDescription)")
                } else {
                    print("✅ NotificationService: 뱃지 초기화 완료")
                }
            }
        }
    }

    // MARK: - FCM Token 관리

    /// 현재 FCM 토큰 가져오기
    func getFCMToken(completion: @escaping (String?) -> Void) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ NotificationService: FCM 토큰 가져오기 실패 - \(error.localizedDescription)")
                completion(nil)
            } else if let token = token {
                print("✅ NotificationService: FCM 토큰 가져오기 성공")
                completion(token)
            } else {
                print("⚠️ NotificationService: FCM 토큰이 없습니다")
                completion(nil)
            }
        }
    }

    /// FCM 토큰 출력 (디버그용)
    func printFCMToken() {
        getFCMToken { token in
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔥 현재 FCM Token")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            if let token = token {
                print("📲 Token:")
                print(token)
            } else {
                print("⚠️ Token을 가져올 수 없습니다")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }

    /// FCM 토큰 삭제 (로그아웃 시 사용)
    func deleteFCMToken(completion: ((Error?) -> Void)? = nil) {
        Messaging.messaging().deleteToken { error in
            if let error = error {
                print("❌ NotificationService: FCM 토큰 삭제 실패 - \(error.localizedDescription)")
                completion?(error)
            } else {
                print("✅ NotificationService: FCM 토큰 삭제 완료")
                UserDefaults.standard.removeObject(forKey: "fcmToken")
                completion?(nil)
            }
        }
    }
}

// MARK: - 소비기한 알림 관리

extension NotificationService {

    /// 재료의 소비기한 알림 스케줄링
    /// - Parameters:
    ///   - ingredient: 알림을 등록할 재료
    ///   - completion: 등록 완료 콜백 (성공 개수)
    func scheduleExpiryNotifications(for ingredient: FridgeIngredientDetail, completion: ((Int) -> Void)? = nil) {
        guard let expirationDate = ingredient.expirationDate else {
            print("⚠️ NotificationService: 소비기한이 없는 재료 [\(ingredient.name)]")
            completion?(0)
            return
        }

        // 이미 지난 소비기한 알림 등록 안 함
        guard expirationDate > Date() else {
            print("⚠️ NotificationService: 이미 지난 소비기한 [\(ingredient.name)] - \(expirationDate)")
            completion?(0)
            return
        }

        print("\n📅 NotificationService: 알림 스케줄링 시작 [\(ingredient.name)]")
        print("   소비기한: \(formatDate(expirationDate))")

        // 설정값 로드
        let settings = ExpirationNotificationSettingsManager.shared
        let notificationDays = settings.loadNotificationDays()
        let notificationTime = settings.loadNotificationTime()

        let notificationDates = calculateNotificationDates(from: expirationDate, days: notificationDays)
        var successCount = 0

        let group = DispatchGroup()

        for (daysBeforeExpiration, date) in notificationDates {
            // 이미 지난 날짜는 스킵
            guard date > Date() else {
                print("   ⏭️  [D-\(daysBeforeExpiration)] 이미 지난 날짜 - \(formatDate(date))")
                continue
            }

            group.enter()

            let request = createNotificationRequest(
                for: ingredient,
                daysBeforeExpiration: daysBeforeExpiration,
                triggerDate: date,
                notificationTime: notificationTime
            )

            addNotificationRequest(request) { error in
                if error == nil {
                    successCount += 1
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("✅ NotificationService: 알림 스케줄링 완료 [\(ingredient.name)] - \(successCount)개 등록\n")

            // Analytics 로깅: 알림 스케줄 등록
            if successCount > 0 {
                AnalyticsService.shared.logNotificationScheduled(
                    notificationType: "expiry",
                    count: successCount,
                    ingredientName: ingredient.name
                )
            }

            completion?(successCount)
        }
    }

    /// 재료의 모든 소비기한 알림 삭제
    /// - Parameter ingredient: 알림을 삭제할 재료
    func removeExpiryNotifications(for ingredient: FridgeIngredientDetail) {
        // 모든 가능한 알림 날짜에 대해 삭제 (0~7일 전)
        let identifiers = (0...7).map { makeNotificationIdentifier(ingredientId: ingredient.id, daysBeforeExpiration: $0) }
        removePendingNotifications(withIdentifiers: identifiers)
        print("🗑️ NotificationService: 소비기한 알림 삭제 [\(ingredient.name)]")
    }

    /// 재료의 소비기한 알림 업데이트 (기존 삭제 후 재등록)
    /// - Parameters:
    ///   - ingredient: 업데이트할 재료
    ///   - completion: 완료 콜백
    func updateExpiryNotifications(for ingredient: FridgeIngredientDetail, completion: ((Int) -> Void)? = nil) {
        // 기존 알림 삭제
        removeExpiryNotifications(for: ingredient)

        // 새로운 알림 등록
        scheduleExpiryNotifications(for: ingredient, completion: completion)
    }

    // MARK: - Private Helpers

    /// 소비기한으로부터 알림 날짜 계산
    /// - Parameters:
    ///   - expirationDate: 소비기한
    ///   - days: 알림을 받을 날짜 배열 (소비기한 X일 전)
    /// - Returns: [(소비기한 며칠 전, 알림 날짜)] 배열
    private func calculateNotificationDates(from expirationDate: Date, days: [Int]) -> [(Int, Date)] {
        let calendar = Calendar.current

        return days.compactMap { daysBeforeExpiration in
            if daysBeforeExpiration == 0 {
                return (0, expirationDate) // D-Day
            } else {
                guard let date = calendar.date(byAdding: .day, value: -daysBeforeExpiration, to: expirationDate) else {
                    return nil
                }
                return (daysBeforeExpiration, date)
            }
        }
    }

    /// 알림 요청 생성
    /// - Parameters:
    ///   - ingredient: 재료
    ///   - daysBeforeExpiration: 소비기한 며칠 전
    ///   - triggerDate: 알림 발송 날짜
    ///   - notificationTime: 알림 시간
    /// - Returns: UNNotificationRequest
    private func createNotificationRequest(
        for ingredient: FridgeIngredientDetail,
        daysBeforeExpiration: Int,
        triggerDate: Date,
        notificationTime: Date
    ) -> UNNotificationRequest {
        // 알림 콘텐츠
        let content = UNMutableNotificationContent()
        content.title = "\(ingredient.name) 소비기한 알림"
        content.body = makeNotificationMessage(ingredientName: ingredient.name, daysBeforeExpiration: daysBeforeExpiration)
        content.sound = .default
        content.badge = 1

        // 트리거 날짜 및 시간 설정
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: triggerDate)

        let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // 식별자 생성
        let identifier = makeNotificationIdentifier(ingredientId: ingredient.id, daysBeforeExpiration: daysBeforeExpiration)

        let timeString = String(format: "%02d:%02d", timeComponents.hour ?? 0, timeComponents.minute ?? 0)
        print("   📌 [D-\(daysBeforeExpiration)] \(formatDate(triggerDate)) \(timeString) - \(content.body)")

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    /// 알림 식별자 생성
    /// - Parameters:
    ///   - ingredientId: 재료 ID
    ///   - daysBeforeExpiration: 소비기한 며칠 전
    /// - Returns: 알림 식별자
    private func makeNotificationIdentifier(ingredientId: String, daysBeforeExpiration: Int) -> String {
        return "expiry_\(ingredientId)_d\(daysBeforeExpiration)"
    }

    /// 알림 메시지 생성
    /// - Parameters:
    ///   - ingredientName: 재료 이름
    ///   - daysBeforeExpiration: 소비기한 며칠 전
    /// - Returns: 알림 메시지
    private func makeNotificationMessage(ingredientName: String, daysBeforeExpiration: Int) -> String {
        switch daysBeforeExpiration {
        case 0:
            return "오늘 '\(ingredientName)'의 소비기한이에요. 냉장고를 확인하세요!"
        case 1:
            return "'\(ingredientName)'의 소비기한이 하루 남았어요!"
        default:
            return "'\(ingredientName)'의 소비기한이 \(daysBeforeExpiration)일 남았어요."
        }
    }

    /// 날짜 포맷팅 (디버그용)
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
