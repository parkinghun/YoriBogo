//
//  SceneDelegate.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = BaseTabBarController()
        window?.makeKeyAndVisible()

        // 앱 시작 시 레시피 데이터 로드
        loadRecipesIfNeeded()
    }

    // MARK: - Recipe Loading
    private func loadRecipesIfNeeded() {
        RecipeBootstrapService.shared.preloadRecipesOnAppLaunch()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // 앱이 활성화될 때 뱃지 초기화
        NotificationService.shared.clearBadge()

        // 앱 포커스 변경 이벤트 로깅 (활성화)
        AnalyticsService.shared.logAppFocusChanged(isFocused: true)

        // FCM 토큰 출력 (디버그용)
        #if DEBUG
        NotificationService.shared.printFCMToken()
        #endif
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).

        // 앱 포커스 변경 이벤트 로깅 (비활성화)
        AnalyticsService.shared.logAppFocusChanged(isFocused: false)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.

        // Widget/Live Activity Intent 결과를 App Group에서 먼저 동기화
        TimerManager.shared.syncTimersFromSharedState()

        // 타이머 상태 재계산 (백그라운드에서 경과된 시간 반영)
        TimerManager.shared.recalculateTimers()
        print("SceneDelegate: 타이머 상태 재계산 완료")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // 실행 중인 모든 타이머에 대한 알림 스케줄
        TimerManager.shared.scheduleAllNotifications()
        print("SceneDelegate: 백그라운드 진입 - 타이머 알림 스케줄 완료")
    }


}
