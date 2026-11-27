import Foundation

/// Persists the activity log as a JSON file in the app's Documents directory.
@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var log: ActivityLog

    private let fileURL: URL

    static var defaultFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("activities.json")
    }

    init(fileURL: URL = ActivityStore.defaultFileURL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let log = try? JSONDecoder().decode(ActivityLog.self, from: data) {
            self.log = log
        } else {
            self.log = ActivityLog()
        }
    }

    func add(_ records: [ActivityRecord]) {
        let added = log.append(contentsOf: records)
        if !added.isEmpty {
            save()
        }
    }

    func removeAll() {
        log.removeAll()
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(log)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save activities: \(error)")
        }
    }
}
