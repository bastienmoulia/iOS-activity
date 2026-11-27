import Foundation

/// Kind of motion detected by `CMMotionActivityManager`.
enum ActivityType: String, Codable, CaseIterable, Hashable {
    case stationary
    case walking
    case running
    case automotive
    case cycling
    case unknown

    var title: String {
        switch self {
        case .stationary: return "Stationary"
        case .walking: return "Walking"
        case .running: return "Running"
        case .automotive: return "Automotive"
        case .cycling: return "Cycling"
        case .unknown: return "Unknown"
        }
    }

    /// SF Symbol used to represent the activity.
    var symbolName: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .automotive: return "car.fill"
        case .cycling: return "bicycle"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Confidence of the motion activity, mirrors `CMMotionActivityConfidence`.
enum ActivityConfidence: Int, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    static func < (lhs: ActivityConfidence, rhs: ActivityConfidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A saved motion activity change.
struct ActivityRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var startDate: Date
    /// Several activities can be reported at the same time (e.g. stationary in a car).
    var types: [ActivityType]
    var confidence: ActivityConfidence

    init(id: UUID = UUID(), startDate: Date, types: [ActivityType], confidence: ActivityConfidence) {
        self.id = id
        self.startDate = startDate
        let filtered = types.isEmpty ? [.unknown] : types
        // Keep a stable, de-duplicated order so records can be compared.
        self.types = ActivityType.allCases.filter { filtered.contains($0) }
        self.confidence = confidence
    }

    /// The most significant activity, used for the icon.
    var primaryType: ActivityType {
        // Moving activities are more meaningful than `stationary`/`unknown`.
        let priority: [ActivityType] = [.automotive, .cycling, .running, .walking, .stationary, .unknown]
        return priority.first { types.contains($0) } ?? .unknown
    }

    var title: String {
        types.map(\.title).joined(separator: ", ")
    }
}
