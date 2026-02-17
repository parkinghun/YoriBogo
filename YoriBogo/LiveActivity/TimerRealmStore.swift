//
//  TimerRealmStore.swift
//  YoriBogo
//
//  Created by 박성훈 on 1/27/26.
//

import Foundation
import RealmSwift

enum TimerRealmStoreError: Error {
    case appGroupUnavailable
}

struct TimerRealmStore {
    static let appGroupID = "group.com.Leo.YoriBogo"
    private static let realmFileName = "timers.realm"

    static func realm() throws -> Realm {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw TimerRealmStoreError.appGroupUnavailable
        }

        let fileURL = containerURL.appendingPathComponent(realmFileName)
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: String(describing: CookingTimerObject.self)) { oldObject, newObject in
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
                        newObject["soundID"] = "default"
                        newObject["soundSystemSoundID"] = 1005
                        newObject["recipeStepID"] = oldObject["recipeStepID"]
                        newObject["createdAt"] = oldObject["createdAt"] as? Date ?? Date()
                    }
                }
            }
        )
        return try Realm(configuration: config)
    }

    static func migrateFromDefaultRealmIfNeeded() {
        guard let timerRealm = try? realm() else { return }
        if !timerRealm.objects(CookingTimerObject.self).isEmpty {
            return
        }

        let defaultRealm: Realm
        do {
            defaultRealm = try Realm()
        } catch {
            return
        }

        let defaultTimers = defaultRealm.objects(CookingTimerObject.self)
        guard !defaultTimers.isEmpty else { return }

        do {
            try timerRealm.write {
                for object in defaultTimers {
                    let copy = CookingTimerObject()
                    copy.id = object.id
                    copy.title = object.title
                    copy.totalSeconds = object.totalSeconds
                    copy.remainingSeconds = object.remainingSeconds
                    copy.isRunning = object.isRunning
                    copy.startDate = object.startDate
                    copy.endDate = object.endDate
                    copy.pausedDate = object.pausedDate
                    copy.soundID = object.soundID
                    copy.soundSystemSoundID = object.soundSystemSoundID
                    copy.recipeStepID = object.recipeStepID
                    copy.createdAt = object.createdAt
                    timerRealm.add(copy, update: .modified)
                }
            }
        } catch {
            print("❌ 타이머 Realm 마이그레이션 실패: \(error)")
        }
    }
}
