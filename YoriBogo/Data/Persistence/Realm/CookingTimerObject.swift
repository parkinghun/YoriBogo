//
//  CookingTimerObject.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import Foundation
import RealmSwift

/// 요리 타이머 Realm Object
final class CookingTimerObject: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var title: String = ""
    @Persisted var totalSeconds: Int = 0
    @Persisted var remainingSeconds: Int = 0
    @Persisted var isRunning: Bool = false
    @Persisted var startDate: Date?
    @Persisted var endDate: Date?
    @Persisted var pausedDate: Date?
    @Persisted var soundID: String = "default"
    @Persisted var soundSystemSoundID: Int = 1005
    /// 연결된 레시피 단계 ID (옵셔널)
    @Persisted var recipeStepID: String?
    @Persisted var createdAt: Date = Date()

    convenience init(
        title: String,
        totalSeconds: Int,
        recipeStepID: String? = nil
    ) {
        self.init()
        self.title = title
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds
        self.recipeStepID = recipeStepID
    }
}
