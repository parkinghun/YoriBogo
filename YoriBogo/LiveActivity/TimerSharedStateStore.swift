//
//  TimerSharedStateStore.swift
//  YoriBogo
//
//  Created by 박성훈 on 2/26/26.
//

import Foundation

enum SharedTimerStateWriter {
    static let app = "app"
    static let intent = "intent"
}

struct SharedTimerState: Codable, Equatable {
    var timerID: String
    var title: String
    var startTime: Date?
    var endTime: Date?
    var isRunning: Bool
    var remainingSeconds: Int
    var lastUpdatedAt: Date
    var version: Int
    var writer: String?

    init(
        timerID: String,
        title: String,
        startTime: Date?,
        endTime: Date?,
        isRunning: Bool,
        remainingSeconds: Int,
        lastUpdatedAt: Date = Date(),
        version: Int = 0,
        writer: String? = nil
    ) {
        self.timerID = timerID
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.isRunning = isRunning
        self.remainingSeconds = max(0, remainingSeconds)
        self.lastUpdatedAt = lastUpdatedAt
        self.version = max(0, version)
        self.writer = writer
    }
}

private struct SharedTimerStateSnapshot: Codable {
    var schemaVersion: Int
    var activeTimerID: String?
    var statesByTimerID: [String: SharedTimerState]
}

enum TimerSharedStateStore {
    static let appGroupID = "group.com.Leo.YoriBogo"

    private static let schemaVersion = 1
    private static let storageKey = "timer_shared_states_v1"

    static func statesByTimerID() -> [String: SharedTimerState] {
        loadSnapshot().statesByTimerID
    }

    static func states() -> [SharedTimerState] {
        Array(statesByTimerID().values)
            .sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
    }

    static func state(for timerID: String) -> SharedTimerState? {
        statesByTimerID()[timerID]
    }

    static func activeTimerID() -> String? {
        loadSnapshot().activeTimerID
    }

    static func setActiveTimerID(_ timerID: String?) {
        var snapshot = loadSnapshot()
        snapshot.activeTimerID = timerID
        saveSnapshot(snapshot)
    }

    static func upsert(_ state: SharedTimerState, makeActive: Bool = false) {
        var snapshot = loadSnapshot()
        var nextState = state
        nextState.remainingSeconds = max(0, nextState.remainingSeconds)
        snapshot.statesByTimerID[nextState.timerID] = nextState

        if makeActive {
            snapshot.activeTimerID = nextState.timerID
        } else if snapshot.activeTimerID == nil {
            snapshot.activeTimerID = nextState.timerID
        }

        saveSnapshot(snapshot)
    }

    static func remove(timerID: String) {
        var snapshot = loadSnapshot()
        snapshot.statesByTimerID.removeValue(forKey: timerID)

        if snapshot.activeTimerID == timerID {
            snapshot.activeTimerID = snapshot.statesByTimerID.values
                .sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
                .first?.timerID
        }

        saveSnapshot(snapshot)
    }

    static func replaceAll(statesByTimerID: [String: SharedTimerState], activeTimerID: String?) {
        let snapshot = SharedTimerStateSnapshot(
            schemaVersion: schemaVersion,
            activeTimerID: activeTimerID,
            statesByTimerID: statesByTimerID
        )
        saveSnapshot(snapshot)
    }

    static func clear() {
        userDefaults()?.removeObject(forKey: storageKey)
    }

    static func nextVersion(for timerID: String) -> Int {
        (state(for: timerID)?.version ?? -1) + 1
    }

    private static func loadSnapshot() -> SharedTimerStateSnapshot {
        guard let defaults = userDefaults(),
              let data = defaults.data(forKey: storageKey),
              let snapshot = try? makeDecoder().decode(SharedTimerStateSnapshot.self, from: data) else {
            return SharedTimerStateSnapshot(
                schemaVersion: schemaVersion,
                activeTimerID: nil,
                statesByTimerID: [:]
            )
        }

        return snapshot
    }

    private static func saveSnapshot(_ snapshot: SharedTimerStateSnapshot) {
        guard let defaults = userDefaults(),
              let data = try? makeEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    private static func userDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private static func makeEncoder() -> JSONEncoder {
        JSONEncoder()
    }

    private static func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }
}
