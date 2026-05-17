import Foundation
import SwiftUI

/// Editable working copy of a `Habit`. Loaded from the live habit, mutated by
/// the user, and applied back on Save (we don't touch the live habit until
/// the user confirms — Cancel discards everything).
///
/// `isTemplateBased` is true when the habit's category is not `.custom`.
/// In that case the name and icon are locked — template identity shouldn't
/// drift over time, and the UI greys those rows out. Everything else
/// (schedule, days, notifications, cue note) is freely editable on both
/// template and custom habits.
@Observable
final class HabitEditDraft {

    // MARK: Source
    /// Reference to the live SwiftData object. Mutated only on `apply()`.
    let habit: Habit

    // MARK: Editable state
    var name: String
    var iconName: String
    var cueNote: String
    var reminderTime: Date
    var notificationsEnabled: Bool
    var selectedDays: Set<Int>

    // MARK: Init

    init(habit: Habit) {
        self.habit = habit
        self.name = habit.name
        self.iconName = habit.iconName
        self.cueNote = habit.cueNote
        self.reminderTime = habit.notificationTimes.first ?? Self.defaultReminderTime()
        self.notificationsEnabled = !habit.notificationTimes.isEmpty
        self.selectedDays = Self.weekdays(for: habit)
    }

    // MARK: Derived

    /// Template-based habits keep their name and icon. Only custom habits can
    /// rename or pick a new icon.
    var isTemplateBased: Bool {
        habit.category != .custom
    }

    /// "Hydration" / "Movement" / etc for the subtitle.
    var friendlyCategoryName: String {
        switch habit.category {
        case .meds: return "Medication"
        case .water: return "Hydration"
        case .movement: return "Movement"
        case .focus: return "Focus"
        case .sleep: return "Sleep"
        case .transition: return "Transition"
        case .hyperfocusCheckIn: return "Check-in"
        case .custom: return "Habit"
        }
    }

    var canSave: Bool {
        // At least one day must be picked, and (for custom) a non-empty name.
        guard !selectedDays.isEmpty else { return false }
        if !isTemplateBased {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        }
        return isDirty
    }

    /// Returns true when any editable field differs from the source habit.
    /// Drives the Save button enabled state.
    var isDirty: Bool {
        if name != habit.name { return true }
        if iconName != habit.iconName { return true }
        if cueNote != habit.cueNote { return true }
        let sourceTimeOn = !habit.notificationTimes.isEmpty
        if notificationsEnabled != sourceTimeOn { return true }
        if notificationsEnabled,
           let sourceTime = habit.notificationTimes.first,
           !Calendar.current.isDate(sourceTime, equalTo: reminderTime, toGranularity: .minute) {
            return true
        }
        if selectedDays != Self.weekdays(for: habit) { return true }
        return false
    }

    var daysSummary: String {
        switch selectedDays {
        case Set(1...7): return "Every day"
        case [2, 3, 4, 5, 6]: return "Mon — Fri"
        case [1, 7]: return "Sat, Sun"
        case []: return "No days"
        default:
            return selectedDays.sorted().map(Self.shortDayLabel).joined(separator: " · ")
        }
    }

    var reminderTimeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: reminderTime)
    }

    var resolvedScheduleAndCustomDays: (HabitSchedule, Set<Int>) {
        switch selectedDays {
        case Set(1...7): return (.daily, [])
        case [2, 3, 4, 5, 6]: return (.weekdays, [])
        case [1, 7]: return (.weekends, [])
        default: return (.custom, selectedDays)
        }
    }

    // MARK: Apply — write changes back to the live habit

    /// Mutates the live `Habit`. Caller is responsible for saving the context
    /// and rescheduling notifications.
    func apply() {
        if !isTemplateBased {
            habit.name = name.trimmingCharacters(in: .whitespaces)
            habit.iconName = iconName
        }
        habit.cueNote = cueNote.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.notificationTimes = notificationsEnabled ? [reminderTime] : []
        let (schedule, customDays) = resolvedScheduleAndCustomDays
        habit.schedule = schedule
        habit.customDays = customDays
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

    /// Maps a habit's persisted schedule + customDays back to a flat Set<Int>.
    static func weekdays(for habit: Habit) -> Set<Int> {
        switch habit.schedule {
        case .daily: return Set(1...7)
        case .weekdays: return [2, 3, 4, 5, 6]
        case .weekends: return [1, 7]
        case .custom: return habit.customDays
        }
    }

    private static func defaultReminderTime() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 8
        comps.minute = 30
        return Calendar.current.date(from: comps) ?? .now
    }
}
