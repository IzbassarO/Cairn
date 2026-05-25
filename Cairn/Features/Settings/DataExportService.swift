import Foundation
import SwiftData

// MARK: - DataExportService
//
// Turns the user's local data into a single shareable file (CSV or JSON).
// Everything is read straight from SwiftData — nothing leaves the device until
// the user picks a destination in the share sheet.
//
// CSV is one row per stone (the spreadsheet-friendly shape most people want).
// JSON is the full structured schema (habits with nested logs) for anyone who
// wants the complete picture.

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv, json
    var id: String { rawValue }

    var title: String {
        switch self {
        case .csv:  return "Comma-separated values"
        case .json: return "Structured JSON"
        }
    }
    var subtitle: String {
        switch self {
        case .csv:  return "Spreadsheet-friendly · Numbers, Excel, Sheets"
        case .json: return "Developer-friendly · full schema"
        }
    }
    var badge: String { rawValue.uppercased() }
    var fileExtension: String { rawValue }
}

@MainActor
struct DataExportService {

    /// Build the export file and return its URL in the temporary directory.
    /// The caller hands this URL to a share sheet.
    static func makeFile(habits: [Habit], moods: [MoodLog], format: ExportFormat) throws -> URL {
        let data: Data
        switch format {
        case .csv:  data = Data(csv(habits: habits).utf8)
        case .json: data = try json(habits: habits, moods: moods)
        }

        let stamp = filenameDateFormatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Cairn-export-\(stamp).\(format.fileExtension)")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: CSV — one row per stone

    private static func csv(habits: [Habit]) -> String {
        var rows = ["habit,category,placed_at,note"]
        let iso = ISO8601DateFormatter()
        for habit in habits.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            for log in (habit.logs ?? []).sorted(by: { $0.loggedAt < $1.loggedAt }) {
                let cells = [
                    habit.name,
                    habit.category.displayName,
                    iso.string(from: log.loggedAt),
                    log.note ?? ""
                ].map(escapeCSV)
                rows.append(cells.joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n")
    }

    /// Quote fields containing commas, quotes, or newlines (RFC 4180).
    private static func escapeCSV(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: JSON — full schema

    private static func json(habits: [Habit], moods: [MoodLog]) throws -> Data {
        let iso = ISO8601DateFormatter()

        let habitObjects: [[String: Any]] = habits
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { habit in
                let logs: [[String: Any]] = (habit.logs ?? [])
                    .sorted { $0.loggedAt < $1.loggedAt }
                    .map { log in
                        var entry: [String: Any] = ["placedAt": iso.string(from: log.loggedAt)]
                        if let note = log.note, !note.isEmpty { entry["note"] = note }
                        return entry
                    }
                return [
                    "name": habit.name,
                    "category": habit.category.displayName,
                    "createdAt": iso.string(from: habit.createdAt),
                    "isArchived": habit.isArchived,
                    "stones": logs
                ]
            }

        let moodObjects: [[String: Any]] = moods
            .sorted { $0.day < $1.day }
            .map { ["day": iso.string(from: $0.day), "mood": $0.mood.label] }

        let root: [String: Any] = [
            "app": "Cairn",
            "exportedAt": iso.string(from: Date()),
            "habits": habitObjects,
            "moods": moodObjects
        ]

        return try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        )
    }

    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
