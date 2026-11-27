import Foundation

/// Ordered list of activity records with the merge rules used when new
/// activities are received from `CMMotionActivityManager`.
struct ActivityLog: Codable, Equatable {
    /// Records sorted by `startDate`, oldest first.
    private(set) var records: [ActivityRecord] = []

    init(records: [ActivityRecord] = []) {
        self.records = records.sorted { $0.startDate < $1.startDate }
    }

    /// Start date of the most recent record.
    var lastDate: Date? {
        records.last?.startDate
    }

    /// Records sorted from the most recent to the oldest, for display.
    var newestFirst: [ActivityRecord] {
        records.reversed()
    }

    /// Appends new records.
    ///
    /// - Records older than or equal to the last saved record are ignored, so
    ///   querying an overlapping history range does not create duplicates.
    /// - Consecutive records with the same activity types are collapsed, only
    ///   activity changes are kept.
    ///
    /// - Returns: the records that were actually added.
    @discardableResult
    mutating func append(contentsOf newRecords: [ActivityRecord]) -> [ActivityRecord] {
        var added: [ActivityRecord] = []
        for record in newRecords.sorted(by: { $0.startDate < $1.startDate }) {
            if let last = records.last {
                if record.startDate <= last.startDate { continue }
                if record.types == last.types { continue }
            }
            records.append(record)
            added.append(record)
        }
        return added
    }

    /// Date until which the given record lasted (start of the next record).
    func endDate(of record: ActivityRecord) -> Date? {
        guard let index = records.firstIndex(where: { $0.id == record.id }),
              index + 1 < records.count else { return nil }
        return records[index + 1].startDate
    }

    mutating func removeAll() {
        records.removeAll()
    }
}
