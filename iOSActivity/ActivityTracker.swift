import CoreMotion
import Foundation

/// Tracks motion activities with `CMMotionActivityManager`.
///
/// The motion coprocessor records activities continuously, even when the app
/// is suspended or not running, and keeps the last 7 days. The tracker:
/// - receives live updates while the app is in the foreground,
/// - queries the activities recorded while the app was in background each time
///   the app becomes active or a background refresh task runs.
@MainActor
final class ActivityTracker: ObservableObject {
    static let shared = ActivityTracker()

    /// Maximum history kept by the system.
    static let maxHistory: TimeInterval = 7 * 24 * 60 * 60

    let store: ActivityStore

    @Published private(set) var authorizationStatus = CMMotionActivityManager.authorizationStatus()
    @Published private(set) var isTracking = false
    @Published private(set) var lastError: String?

    private let manager = CMMotionActivityManager()
    private let queryQueue = OperationQueue()
    private var isAppActive = false

    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    init(store: ActivityStore = ActivityStore()) {
        self.store = store
    }

    /// Called when the app becomes active: saves the activities recorded while
    /// the app was in background, then starts live updates.
    func appDidBecomeActive() async {
        isAppActive = true
        // History must be saved before live updates, otherwise a live record
        // would be newer than the background history and the history would be ignored.
        await syncHistory()
        if isAppActive {
            startLiveUpdates()
        }
    }

    /// Called when the app goes to background.
    func appDidEnterBackground() {
        isAppActive = false
        stopLiveUpdates()
    }

    /// Starts live activity updates (foreground).
    private func startLiveUpdates() {
        guard isAvailable, !isTracking else { return }
        isTracking = true
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            let record = ActivityRecord(activity)
            MainActor.assumeIsolated {
                guard let self else { return }
                self.store.add([record])
                self.authorizationStatus = CMMotionActivityManager.authorizationStatus()
            }
        }
    }

    private func stopLiveUpdates() {
        guard isTracking else { return }
        manager.stopActivityUpdates()
        isTracking = false
    }

    /// Saves the activities recorded by the system since the last saved activity.
    func syncHistory() async {
        guard isAvailable else {
            lastError = "Motion activity is not available on this device."
            return
        }
        let now = Date()
        let oldest = now.addingTimeInterval(-Self.maxHistory)
        let from = max(store.log.lastDate ?? oldest, oldest)

        let result: Result<[ActivityRecord], Error> = await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: from, to: now, to: queryQueue) { activities, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success((activities ?? []).map(ActivityRecord.init)))
                }
            }
        }

        authorizationStatus = CMMotionActivityManager.authorizationStatus()
        switch result {
        case .success(let records):
            store.add(records)
            lastError = nil
        case .failure(let error):
            lastError = error.localizedDescription
        }
    }
}

extension ActivityRecord {
    init(_ activity: CMMotionActivity) {
        var types: [ActivityType] = []
        if activity.stationary { types.append(.stationary) }
        if activity.walking { types.append(.walking) }
        if activity.running { types.append(.running) }
        if activity.automotive { types.append(.automotive) }
        if activity.cycling { types.append(.cycling) }
        if activity.unknown { types.append(.unknown) }

        let confidence: ActivityConfidence
        switch activity.confidence {
        case .high: confidence = .high
        case .medium: confidence = .medium
        default: confidence = .low
        }

        self.init(startDate: activity.startDate, types: types, confidence: confidence)
    }
}
