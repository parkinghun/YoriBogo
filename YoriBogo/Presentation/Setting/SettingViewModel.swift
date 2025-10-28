//
//  SettingViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/14/25.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Setting Models

enum SettingSection: Int, CaseIterable {
    case notification = 0
    case timer = 1
    case statistics = 2
    case appInfo = 3

    var title: String {
        switch self {
        case .notification: return "알림 설정"
        case .timer: return "타이머 설정"
        case .statistics: return "통계"
        case .appInfo: return "앱 정보"
        }
    }

    var items: [SettingItem] {
        switch self {
        case .notification:
            return [
                .notificationTiming,
                .notificationTime
            ]
        case .timer:
            return [
                .timerSound,
                .defaultTimerDuration
            ]
        case .statistics:
            return [.monthlyStats]
        case .appInfo:
            return [
                .appVersion,
                .inquiry,
                .privacyPolicy
            ]
        }
    }
}

enum SettingItem {
    // 알림 설정
    case notificationTiming
    case notificationTime

    // 타이머 설정
    case timerSound
    case defaultTimerDuration

    // 통계
    case monthlyStats

    // 앱 정보
    case appVersion
    case inquiry
    case privacyPolicy

    var title: String {
        switch self {
        case .notificationTiming: return "소비기한 알림 시점"
        case .notificationTime: return "알림 시간"
        case .timerSound: return "알림음"
        case .defaultTimerDuration: return "기본 타이머 시간"
        case .monthlyStats: return "이번 달 소비/폐기 현황"
        case .appVersion: return "버전 정보"
        case .inquiry: return "문의하기"
        case .privacyPolicy: return "개인정보 처리방침"
        }
    }

    var cellType: SettingCellType {
        switch self {
        case .notificationTiming, .timerSound, .defaultTimerDuration:
            return .disclosure
        case .notificationTime:
            return .value
        case .monthlyStats:
            return .button
        case .appVersion:
            return .value
        case .inquiry, .privacyPolicy:
            return .disclosure
        }
    }

    var icon: String? {
        switch self {
        case .notificationTiming: return "bell.badge"
        case .notificationTime: return "clock"
        case .timerSound: return "speaker.wave.2"
        case .defaultTimerDuration: return "timer"
        case .monthlyStats: return "chart.bar"
        case .appVersion: return "info.circle"
        case .inquiry: return "envelope"
        case .privacyPolicy: return "lock.shield"
        }
    }
}

enum SettingCellType {
    case disclosure  // 화살표 (다음 화면으로 이동)
    case value       // 값 표시 (클릭 불가)
    case button      // 버튼 스타일 (클릭 가능)
}

// MARK: - ViewModel

final class SettingViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let sections: Driver<[SettingSection]>
        let notificationTime: Driver<String>
        let appVersion: Driver<String>
        let itemSelected: Driver<SettingItem>
    }

    private let disposeBag = DisposeBag()

    init() { }

    func transform(input: Input) -> Output {
        // 섹션 데이터
        let sections = input.viewDidLoad
            .map { SettingSection.allCases }
            .asDriver(onErrorJustReturn: [])

        // 알림 시간 (UserDefaults에서 가져오거나 기본값)
        let notificationTime = input.viewDidLoad
            .map { UserDefaults.standard.string(forKey: "notificationTime") ?? "17:00" }
            .asDriver(onErrorJustReturn: "17:00")

        let appVersion = input.viewDidLoad
            .map {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                return "\(version)"
            }
            .asDriver(onErrorJustReturn: "1.0.0")

        // 아이템 선택
        let itemSelected = input.itemSelected
            .map { indexPath -> SettingItem in
                let section = SettingSection.allCases[indexPath.section]
                return section.items[indexPath.row]
            }
            .asDriver(onErrorJustReturn: .appVersion)

        return Output(
            sections: sections,
            notificationTime: notificationTime,
            appVersion: appVersion,
            itemSelected: itemSelected
        )
    }
}
