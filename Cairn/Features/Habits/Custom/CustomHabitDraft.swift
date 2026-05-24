import Foundation
import SwiftUI

@Observable
final class CustomHabitDraft {

    // MARK: Identity
    var iconName: String = "leaf"
    var name: String = ""

    // MARK: Schedule
    var reminderTimes: [Date]
    var selectedDays: Set<Int> = Set(1...7)
    var notificationsEnabled: Bool = true

    // MARK: Cue
    var cueNote: String = ""

    // MARK: Cap
    var targetPerDay: Int = 1

    // MARK: Init

    init() {
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

    var resolvedScheduleAndCustomDays: (HabitSchedule, Set<Int>) {
        switch selectedDays {
        case Set(1...7): return (.daily, [])
        case [2, 3, 4, 5, 6]: return (.weekdays, [])
        case [1, 7]: return (.weekends, [])
        default: return (.custom, selectedDays)
        }
    }

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

    var reminderTimesLabel: String {
        guard !reminderTimes.isEmpty else { return "Tap to set" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return reminderTimes.map(f.string(from:)).joined(separator: " · ")
    }

    // MARK: Reminder array bookkeeping
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
