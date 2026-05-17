import Foundation
import SwiftUI

/// Mutable draft used by the Custom Habit screen (F7).
///
/// Unlike `FirstHabitDraft`, which copies fields from a template and lets the
/// user adjust a few, this draft starts blank and the user fills everything in.
///
/// Field grouping (matching the F7 layout):
///  - identity: `iconName`, `name`
///  - schedule: `reminderTimes`, `selectedDays`, `notificationsEnabled`
///  - cue & note: `cueNote`
///  - cap: `targetPerDay` (default 1)
@Observable
final class CustomHabitDraft {

    // MARK: Identity
    var iconName: String = "leaf"
    var name: String = ""

    // MARK: Schedule
    /// One Date per planned reminder time. Count == `targetPerDay`. When the
    /// user changes the target, `syncReminderTimesToTarget` adjusts the array.
    var reminderTimes: [Date]
    /// Picked days as weekday ints (1=Sun … 7=Sat).
    var selectedDays: Set<Int> = Set(1...7)
    /// When false, `reminderTimes` is ignored at save and the habit has no
    /// notifications. The Reminder row in F7 is disabled but still visible.
    var notificationsEnabled: Bool = true

    // MARK: Cue
    var cueNote: String = ""

    // MARK: Cap
    /// Allowed values: 1...3 in v1.0. Beyond that the UI gets noisy and the
    /// behavior is rarely useful (this isn't a tally counter app).
    var targetPerDay: Int = 1

    // MARK: Init

    init() {
        // Start with one reminder at 08:30 today.
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 8
        comps.minute = 30
        self.reminderTimes = [Calendar.current.date(from: comps) ?? .now]
    }

    // MARK: Derived

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !selectedDays.isEmpty
    }

    /// Resolves `selectedDays` into the persisted `HabitSchedule + customDays`
    /// shape that `Habit` expects.
    var resolvedScheduleAndCustomDays: (HabitSchedule, Set<Int>) {
        switch selectedDays {
        case Set(1...7): return (.daily, [])
        case [2, 3, 4, 5, 6]: return (.weekdays, [])
        case [1, 7]: return (.weekends, [])
        default: return (.custom, selectedDays)
        }
    }

    /// Human-readable summary for the F7 Days row.
    var daysSummary: String {
        switch selectedDays {
        case Set(1...7): return "Every day"
        case [2, 3, 4, 5, 6]: return "Weekdays"
        case [1, 7]: return "Weekends"
        case []: return "No days"
        default:
            return selectedDays.sorted().map(Self.shortDayLabel).joined(separator: " · ")
        }
    }

    /// Comma-separated time labels for the F7 Reminder row.
    var reminderTimesLabel: String {
        guard !reminderTimes.isEmpty else { return "Tap to set" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return reminderTimes.map(f.string(from:)).joined(separator: " · ")
    }

    // MARK: Reminder array bookkeeping

    /// Called when `targetPerDay` changes. Grows or shrinks `reminderTimes`
    /// to match the new count. New slots are seeded one hour after the last
    /// existing slot (or 08:30 if empty).
    func syncReminderTimesToTarget() {
        let cap = max(1, min(targetPerDay, 3))
        if reminderTimes.count == cap { return }

        if reminderTimes.count > cap {
            reminderTimes = Array(reminderTimes.prefix(cap))
            return
        }

        let cal = Calendar.current
        var seed: Date
        if let last = reminderTimes.last {
            seed = cal.date(byAdding: .hour, value: 1, to: last) ?? last
        } else {
            var comps = cal.dateComponents([.year, .month, .day], from: .now)
            comps.hour = 8
            comps.minute = 30
            seed = cal.date(from: comps) ?? .now
        }
        while reminderTimes.count < cap {
            reminderTimes.append(seed)
            seed = cal.date(byAdding: .hour, value: 1, to: seed) ?? seed
        }
    }

    // MARK: Helpers

    static func shortDayLabel(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "?"
        }
    }
}
