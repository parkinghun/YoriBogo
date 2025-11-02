//
//  RecentSearchManager.swift
//  YoriBogo
//
//  Created by Claude on 2025-11-02.
//

import Foundation
import RxSwift
import RxCocoa

/// 최근 검색어를 UserDefaults에 저장하고 관리하는 매니저
final class RecentSearchManager {
    static let shared = RecentSearchManager()

    private let userDefaults = UserDefaults.standard
    private let key = "recentSearchKeywords"
    private let maxCount = 10 // 최대 저장 개수

    // 최근 검색어 리스트를 Observable로 제공
    private let recentSearchesRelay = BehaviorRelay<[String]>(value: [])

    var recentSearches: Observable<[String]> {
        return recentSearchesRelay.asObservable()
    }

    private init() {
        // 초기 데이터 로드
        recentSearchesRelay.accept(loadRecentSearches())
    }

    // MARK: - Public Methods

    /// 검색어 추가 (중복 제거, 최신순 정렬)
    /// - Parameter keyword: 추가할 검색어
    func addSearchKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        // 빈 문자열은 저장하지 않음
        guard !trimmed.isEmpty else { return }

        var searches = loadRecentSearches()

        // 기존에 있던 검색어는 제거
        searches.removeAll { $0 == trimmed }

        // 맨 앞에 새 검색어 추가
        searches.insert(trimmed, at: 0)

        // 최대 개수 제한
        if searches.count > maxCount {
            searches = Array(searches.prefix(maxCount))
        }

        // 저장
        saveRecentSearches(searches)
        recentSearchesRelay.accept(searches)
    }

    /// 특정 검색어 삭제
    /// - Parameter keyword: 삭제할 검색어
    func removeSearchKeyword(_ keyword: String) {
        var searches = loadRecentSearches()
        searches.removeAll { $0 == keyword }

        saveRecentSearches(searches)
        recentSearchesRelay.accept(searches)
    }

    /// 전체 검색어 삭제
    func clearAllSearches() {
        userDefaults.removeObject(forKey: key)
        recentSearchesRelay.accept([])
    }

    // MARK: - Private Methods

    /// UserDefaults에서 최근 검색어 로드
    /// - Returns: 최근 검색어 배열
    private func loadRecentSearches() -> [String] {
        return userDefaults.stringArray(forKey: key) ?? []
    }

    /// UserDefaults에 최근 검색어 저장
    /// - Parameter searches: 저장할 검색어 배열
    private func saveRecentSearches(_ searches: [String]) {
        userDefaults.set(searches, forKey: key)
    }
}
