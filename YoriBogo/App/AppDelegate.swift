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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        IQKeyboardManager.shared.isEnabled = true

        configureRealm()
        FirebaseApp.configure()
        configurePushNotifications(application)

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
                print("✅ AppDelegate: 알림 권한 허용됨")
                // APNs 등록 (권한 허용 시)
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("⚠️ AppDelegate: 알림 권한 거부됨 - 설정에서 변경 가능")
            }
        }
    }

    // MARK: - APNs Registration

    /// APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 APNs Device Token: \(token)")

        // APNs 토큰을 FCM에 전달
        Messaging.messaging().apnsToken = deviceToken
    }

    /// APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs 등록 실패: \(error.localizedDescription)")
    }
    
    // MARK: - Realm Configuration
    private func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 필요 시 마이그레이션 로직 추가
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config

        // Realm 초기화 확인
        do {
            _ = try Realm()
            print("Realm 초기화 성공")
        } catch {
            print("Realm 초기화 실패: \(error)")
        }
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

        print("📬 Foreground 알림 수신: \(notification.request.content.title)")
    }

    /// 사용자가 알림을 탭했을 때 호출
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        print("🔔 알림 탭됨: \(identifier)")

        // 뱃지 초기화
        NotificationService.shared.clearBadge()

        // 소비기한 알림인 경우 냉장고 화면으로 이동
        if identifier.hasPrefix("expiry_") {
            navigateToFridgeScreen()
            print("   → 소비기한 알림: 냉장고 화면으로 이동")
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
                print("⚠️ AppDelegate: TabBarController를 찾을 수 없습니다.")
                return
            }

            // 냉장고 탭으로 전환 (index 0)
            tabBarController.selectedIndex = 0

            // 네비게이션 스택 최상단으로 이동 (푸시된 화면이 있다면 팝)
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }

            print("✅ AppDelegate: 냉장고 화면으로 이동 완료")
        }
    }
}

// MARK: - MessagingDelegate (FCM)

extension AppDelegate: MessagingDelegate {

    /// FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔥 FCM Registration Token 수신")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        if let token = fcmToken {
            print("📲 FCM Token:")
            print(token)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

            // TODO: 서버에 FCM 토큰 전송
            // 예: APIService.shared.registerFCMToken(token)

            // UserDefaults에 저장 (선택사항)
            UserDefaults.standard.set(token, forKey: "fcmToken")
        } else {
            print("⚠️ FCM Token이 nil입니다.\n")
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
