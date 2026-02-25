//
//  AppDelegate.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import IQKeyboardManagerSwift
import RealmSwift
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        IQKeyboardManager.shared.isEnabled = true

        configureRealm()
        configurePushNotifications(application)

        FirebaseApp.configure()
        // 기본 이벤트 자동 수집 활성화
        Analytics.setAnalyticsCollectionEnabled(true)

        // 앱 실행 이벤트 로깅
        AnalyticsService.shared.logAppOpen()

        if #available(iOS 17.1, *) {
            LiveActivityManager.shared.endAll()
        }

        return true
    }

    // MARK: - Push Notifications Configuration

    private func configurePushNotifications(_ application: UIApplication) {
        // UNUserNotificationCenterDelegate 설정
        UNUserNotificationCenter.current().delegate = self

        // FCM Delegate 설정
        Messaging.messaging().delegate = self

        // NotificationService를 통한 권한 요청
        NotificationService.shared.requestAuthorization { granted in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - APNs Registration

    /// APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    /// APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    // MARK: - Realm Configuration
    private func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: CookingTimerObject.className()) { oldObject, newObject in
                        guard let oldObject, let newObject else { return }

                        let duration = oldObject["duration"] as? Double ?? 0
                        let remaining = oldObject["remainingOnPause"] as? Double ?? duration
                        let state = oldObject["state"] as? String
                        let startDate = oldObject["startDate"] as? Date

                        newObject["title"] = oldObject["title"] as? String ?? "타이머"
                        newObject["totalSeconds"] = Int(duration)
                        newObject["remainingSeconds"] = Int(remaining)
                        newObject["isRunning"] = (state == "running")
                        newObject["startDate"] = startDate
                        if let startDate {
                            newObject["endDate"] = startDate.addingTimeInterval(TimeInterval(Int(remaining)))
                        }
                        newObject["pausedDate"] = nil
                        newObject["soundID"] = TimerSettings.selectedSoundOption().id
                        newObject["soundSystemSoundID"] = TimerSettings.selectedSoundOption().systemSoundID
                        newObject["recipeStepID"] = oldObject["recipeStepID"]
                        newObject["createdAt"] = oldObject["createdAt"] as? Date ?? Date()
                    }
                }

                if oldSchemaVersion < 3 {
                    // RecipeStepObject에 timerSeconds 필드 추가 (옵셔널 기본값 nil)
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config

        // Realm 초기화 확인
        _ = try? Realm()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// 앱이 Foreground 상태일 때 알림 수신 시 호출
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 앱이 실행 중이어도 알림 배너, 소리, 배지 표시
        completionHandler([.banner, .list, .sound, .badge])

        let title = notification.request.content.title
        let identifier = notification.request.identifier

        // Analytics 로깅: 알림 실제 발송
        let notificationType = identifier.hasPrefix("expiry_") ? "expiry" : (identifier.hasPrefix("test_") ? "test" : "push")
        AnalyticsService.shared.logNotificationTriggered(
            notificationTitle: title,
            notificationType: notificationType
        )
    }

    /// 사용자가 알림을 탭했을 때 호출
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        // Analytics 로깅: 알림 클릭
        let notificationType = identifier.hasPrefix("expiry_") ? "expiry" : (identifier.hasPrefix("test_") ? "test" : "push")
        AnalyticsService.shared.logNotificationClicked(
            notificationId: identifier,
            notificationType: notificationType
        )

        // 뱃지 초기화
        NotificationService.shared.clearBadge()

        // 소비기한 알림인 경우 냉장고 화면으로 이동
        if identifier.hasPrefix("expiry_") {
            navigateToFridgeScreen()
        }
        // 타이머 알림인 경우 타이머 화면으로 이동
        else if identifier.hasPrefix("timer_") {
            navigateToTimerScreen()
        }

        completionHandler()
    }

    /// 냉장고 화면으로 이동
    private func navigateToFridgeScreen() {
        // 메인 스레드에서 실행
        DispatchQueue.main.async {
            // 현재 활성화된 윈도우 씬 찾기
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let tabBarController = window.rootViewController as? UITabBarController else {
                return
            }

            // 냉장고 탭으로 전환 (index 0)
            tabBarController.selectedIndex = 0

            // 네비게이션 스택 최상단으로 이동 (푸시된 화면이 있다면 팝)
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
    }

    /// 타이머 화면으로 이동
    private func navigateToTimerScreen() {
        // 메인 스레드에서 실행
        DispatchQueue.main.async {
            // 현재 활성화된 윈도우 씬 찾기
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let tabBarController = window.rootViewController as? UITabBarController else {
                return
            }

            // 타이머 탭으로 전환 (index 3)
            tabBarController.selectedIndex = 3

            // 네비게이션 스택 최상단으로 이동 (푸시된 화면이 있다면 팝)
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
    }
}

// MARK: - MessagingDelegate (FCM)

extension AppDelegate: MessagingDelegate {

    /// FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            // Analytics 로깅: FCM 토큰 수신
            AnalyticsService.shared.logFCMTokenReceived(tokenLength: token.count)

            // TODO: 서버에 FCM 토큰 전송
            // 예: APIService.shared.registerFCMToken(token)

            // UserDefaults에 저장 (선택사항)
            UserDefaults.standard.set(token, forKey: "fcmToken")
        }

        // 토큰 정보를 딕셔너리 형태로도 출력 (Firebase Console에서 테스트용)
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
