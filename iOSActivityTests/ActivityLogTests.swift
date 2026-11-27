import XCTest
@testable import iOSActivity

final class ActivityLogTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func record(_ offset: TimeInterval, _ types: [ActivityType], _ confidence: ActivityConfidence = .high) -> ActivityRecord {
        ActivityRecord(startDate: start.addingTimeInterval(offset), types: types, confidence: confidence)
    }

    func testAppendSortsRecordsByDate() {
        var log = ActivityLog()
        log.append(contentsOf: [record(60, [.walking]), record(0, [.stationary]), record(120, [.automotive])])

        XCTAssertEqual(log.records.map(\.types), [[.stationary], [.walking], [.automotive]])
        XCTAssertEqual(log.newestFirst.map(\.types), [[.automotive], [.walking], [.stationary]])
        XCTAssertEqual(log.lastDate, start.addingTimeInterval(120))
    }

    func testAppendCollapsesConsecutiveIdenticalActivities() {
        var log = ActivityLog()
        let added = log.append(contentsOf: [
            record(0, [.walking], .low),
            record(10, [.walking], .high),
            record(20, [.running]),
            record(30, [.walking]),
        ])

        XCTAssertEqual(added.count, 3)
        XCTAssertEqual(log.records.map(\.types), [[.walking], [.running], [.walking]])
    }

    func testAppendIgnoresAlreadySavedHistory() {
        var log = ActivityLog()
        log.append(contentsOf: [record(0, [.stationary]), record(60, [.walking])])

        // Overlapping history query returns the same activities again plus a new one.
        let added = log.append(contentsOf: [record(0, [.stationary]), record(60, [.walking]), record(120, [.cycling])])

        XCTAssertEqual(added.map(\.types), [[.cycling]])
        XCTAssertEqual(log.records.count, 3)
    }

    func testEndDateIsStartOfNextRecord() {
        var log = ActivityLog()
        log.append(contentsOf: [record(0, [.stationary]), record(90, [.walking])])

        XCTAssertEqual(log.endDate(of: log.records[0]), start.addingTimeInterval(90))
        XCTAssertNil(log.endDate(of: log.records[1]))
    }

    func testRecordNormalizesTypes() {
        let empty = ActivityRecord(startDate: start, types: [], confidence: .low)
        XCTAssertEqual(empty.types, [.unknown])

        let combined = ActivityRecord(startDate: start, types: [.automotive, .stationary, .automotive], confidence: .medium)
        XCTAssertEqual(combined.types, [.stationary, .automotive])
        XCTAssertEqual(combined.primaryType, .automotive)
        XCTAssertEqual(combined.title, "Stationary, Automotive")
    }

    func testLogIsCodable() throws {
        var log = ActivityLog()
        log.append(contentsOf: [record(0, [.stationary]), record(60, [.running], .medium)])

        let decoded = try JSONDecoder().decode(ActivityLog.self, from: JSONEncoder().encode(log))
        XCTAssertEqual(decoded, log)
    }
}
