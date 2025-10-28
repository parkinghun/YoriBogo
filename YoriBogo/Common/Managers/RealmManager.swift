//
//  RealmManager.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-09.
//

import Foundation
import RealmSwift

enum RealmError: LocalizedError {
    case initializationFailed
    case objectNotFound
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "데이터베이스 초기화에 실패했습니다"
        case .objectNotFound:
            return "데이터를 찾을 수 없습니다"
        case .writeFailed:
            return "데이터 저장에 실패했습니다"
        }
    }
}

class RealmManager {
    /// 안전하게 Realm 인스턴스를 가져옴
    static func getRealm() -> Realm? {
        do {
            return try Realm()
        } catch {
            print("❌ Realm 초기화 에러: \(error)")
            return nil
        }
    }

    /// Realm 작업을 안전하게 실행
    static func performWrite(_ block: (Realm) throws -> Void) throws {
        guard let realm = getRealm() else {
            throw RealmError.initializationFailed
        }

        try realm.write {
            try block(realm)
        }
    }

    /// Realm 읽기 작업을 안전하게 실행
    static func performRead<T>(_ block: (Realm) -> T) -> T? {
        guard let realm = getRealm() else {
            return nil
        }
        return block(realm)
    }

    /// Realm 읽기 작업을 안전하게 실행 (에러 throw)
    static func performReadThrowing<T>(_ block: (Realm) throws -> T) throws -> T {
        guard let realm = getRealm() else {
            throw RealmError.initializationFailed
        }
        return try block(realm)
    }
}
