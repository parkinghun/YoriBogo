//
//  AnalyticsService.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-26.
//

import Foundation
import FirebaseAnalytics

/// Firebase Analytics 이벤트 로깅을 관리하는 서비스
final class AnalyticsService {

    // MARK: - Singleton
    static let shared = AnalyticsService()

    private init() {}

    // MARK: - 앱 라이프사이클 이벤트

    /// 앱 실행 이벤트
    func logAppOpen() {
        Analytics.logEvent("app_open", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    /// 앱 포커스 변경 이벤트
    /// - Parameter isFocused: 포커스 상태 (true: 활성화, false: 비활성화)
    func logAppFocusChanged(isFocused: Bool) {
        Analytics.logEvent("app_focus_changed", parameters: [
            "is_focused": isFocused,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - 알림 권한 이벤트

    /// 알림 권한 허용 이벤트
    func logPushPermissionGranted() {
        Analytics.logEvent("push_permission_granted", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    /// 알림 권한 거부 이벤트
    func logPushPermissionDenied() {
        Analytics.logEvent("push_permission_denied", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - FCM 토큰 이벤트

    /// FCM 토큰 수신 이벤트
    /// - Parameter tokenLength: 토큰 길이 (개인정보 보호를 위해 토큰 자체는 전송하지 않음)
    func logFCMTokenReceived(tokenLength: Int) {
        Analytics.logEvent("fcm_token_received", parameters: [
            "token_length": tokenLength,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - 알림 스케줄 이벤트

    /// 로컬 알림 스케줄 등록 이벤트
    /// - Parameters:
    ///   - notificationType: 알림 타입 (예: "expiry", "test")
    ///   - count: 등록된 알림 개수
    ///   - ingredientName: 재료 이름 (선택)
    func logNotificationScheduled(notificationType: String, count: Int, ingredientName: String? = nil) {
        var parameters: [String: Any] = [
            "notification_type": notificationType,
            "count": count,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let name = ingredientName {
            parameters["ingredient_name"] = name
        }

        Analytics.logEvent("notification_scheduled", parameters: parameters)
    }

    /// 알림 실제 발송 이벤트 (Foreground에서 수신 시)
    /// - Parameters:
    ///   - notificationTitle: 알림 제목
    ///   - notificationType: 알림 타입
    func logNotificationTriggered(notificationTitle: String, notificationType: String) {
        Analytics.logEvent("notification_triggered", parameters: [
            "notification_title": notificationTitle,
            "notification_type": notificationType,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    /// 알림 클릭 이벤트
    /// - Parameters:
    ///   - notificationId: 알림 식별자
    ///   - notificationType: 알림 타입
    func logNotificationClicked(notificationId: String, notificationType: String) {
        Analytics.logEvent("notification_clicked", parameters: [
            "notification_id": notificationId,
            "notification_type": notificationType,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - 레시피 이벤트

    /// 레시피 열람 이벤트
    /// - Parameters:
    ///   - recipeId: 레시피 ID
    ///   - recipeName: 레시피 이름
    ///   - category: 레시피 카테고리
    func logRecipeViewed(recipeId: String, recipeName: String, category: String? = nil) {
        var parameters: [String: Any] = [
            "recipe_id": recipeId,
            "recipe_name": recipeName,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let category = category {
            parameters["category"] = category
        }

        Analytics.logEvent("recipe_viewed", parameters: parameters)
    }

    /// 레시피 즐겨찾기 등록 이벤트
    /// - Parameters:
    ///   - recipeId: 레시피 ID
    ///   - recipeName: 레시피 이름
    ///   - category: 레시피 카테고리
    func logRecipeFavorited(recipeId: String, recipeName: String, category: String? = nil) {
        var parameters: [String: Any] = [
            "recipe_id": recipeId,
            "recipe_name": recipeName,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let category = category {
            parameters["category"] = category
        }

        Analytics.logEvent("recipe_favorited", parameters: parameters)
    }

    /// 레시피 즐겨찾기 해제 이벤트
    /// - Parameters:
    ///   - recipeId: 레시피 ID
    ///   - recipeName: 레시피 이름
    ///   - category: 레시피 카테고리
    func logRecipeUnfavorited(recipeId: String, recipeName: String, category: String? = nil) {
        var parameters: [String: Any] = [
            "recipe_id": recipeId,
            "recipe_name": recipeName,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let category = category {
            parameters["category"] = category
        }

        Analytics.logEvent("recipe_unfavorited", parameters: parameters)
    }

    // MARK: - 사용자 속성 설정

    /// 사용자 속성 설정 (예: 알림 권한 상태)
    /// - Parameters:
    ///   - key: 속성 키
    ///   - value: 속성 값
    func setUserProperty(key: String, value: String?) {
        Analytics.setUserProperty(value, forName: key)
    }
}
