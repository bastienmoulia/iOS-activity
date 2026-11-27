import CoreMotion
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var tracker: ActivityTracker
    @EnvironmentObject private var store: ActivityStore
    @State private var isConfirmingClear = false

    var body: some View {
        NavigationStack {
            List {
                if let message = statusMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(sections) { section in
                    Section(section.day.formatted(date: .complete, time: .omitted)) {
                        ForEach(section.records) { record in
                            ActivityRow(record: record, endDate: store.log.endDate(of: record))
                        }
                    }
                }
            }
            .overlay {
                if store.log.records.isEmpty {
                    ContentUnavailableView(
                        "No Activity",
                        systemImage: "figure.walk.motion",
                        description: Text("Activities detected by the motion coprocessor will appear here.")
                    )
                }
            }
            .navigationTitle("Activities")
            .refreshable {
                await tracker.syncHistory()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) {
                        isConfirmingClear = true
                    }
                    .disabled(store.log.records.isEmpty)
                }
            }
            .confirmationDialog("Delete all saved activities?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    store.removeAll()
                }
            }
        }
    }

    private var sections: [DaySection] {
        let calendar = Calendar.current
        var result: [DaySection] = []
        for record in store.log.newestFirst {
            let day = calendar.startOfDay(for: record.startDate)
            if result.last?.day == day {
                result[result.count - 1].records.append(record)
            } else {
                result.append(DaySection(day: day, records: [record]))
            }
        }
        return result
    }

    private var statusMessage: String? {
        if !tracker.isAvailable {
            return "Motion activity is not available on this device."
        }
        switch tracker.authorizationStatus {
        case .denied:
            return "Motion & Fitness access is denied. Enable it in Settings > Privacy & Security > Motion & Fitness."
        case .restricted:
            return "Motion & Fitness access is restricted on this device."
        default:
            return tracker.lastError
        }
    }
}

struct DaySection: Identifiable {
    let day: Date
    var records: [ActivityRecord]

    var id: Date { day }
}

struct ActivityRow: View {
    let record: ActivityRecord
    let endDate: Date?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.primaryType.symbolName)
                .font(.title2)
                .frame(width: 36)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.headline)
                Text(record.startDate.formatted(date: .abbreviated, time: .standard))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let endDate {
                    Text(Duration.seconds(endDate.timeIntervalSince(record.startDate))
                        .formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 2)))
                        .font(.subheadline)
                        .monospacedDigit()
                } else {
                    Text("Now")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                Text(record.confidence.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let tracker = ActivityTracker(store: ActivityStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview.json")))
    return ContentView()
        .environmentObject(tracker)
        .environmentObject(tracker.store)
}
