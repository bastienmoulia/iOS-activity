import BackgroundTasks
import SwiftUI

@main
struct iOSActivityApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var tracker = ActivityTracker.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tracker)
                .environmentObject(tracker.store)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { await tracker.appDidBecomeActive() }
            case .background:
                tracker.appDidEnterBackground()
                BackgroundRefresh.schedule()
            default:
                break
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.taskIdentifier)) {
            // Schedule the next refresh, then save activities recorded meanwhile.
            BackgroundRefresh.schedule()
            await ActivityTracker.shared.syncHistory()
        }
    }
}

/// Background app refresh used to save activities while the app is in background.
enum BackgroundRefresh {
    /// Must match `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
    static let taskIdentifier = "com.bastienmoulia.iOSActivity.refresh"

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}
