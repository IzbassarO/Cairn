import Foundation
import SwiftUI

/// Mutable draft used by the first-habit add flow (F1 → F2/F3 → F5).
/// Initialized from a `HabitTemplate`. The draft is the single source of truth
/// for every sheet in the flow; child sheets bind directly to it.
@Observable
final class FirstHabitDraft {

    // MARK: Identity (from the template, not user-editable in this flow)
    let templateID: String
    let templateName: String
    let templateIcon: String
    let templateColorToken: String
    let templateCategory: HabitCategory
    let templateBlurb: String

    // MARK: User-editable state
    /// Reminder time of day. Optional because some starters (e.g. "Drink water")
    /// don't suggest a time — in that case the user picks one in F2.
    var reminderTime: Date

    /// Picked days as weekday ints (1=Sun … 7=Sat — Apple convention).
    /// We work with the raw set inside the flow; mapping to `HabitSchedule`
    /// happens at save time.
    var selectedDays: Set<Int>

    /// When true, the habit is saved with `notificationTimes = [reminderTime]`.
    /// When false, the habit is saved with `notificationTimes = []`
    /// (no notifications scheduled, no permission prompted).
    var notificationsEnabled: Bool

    // MARK: Derived

    /// Human-readable summary of the day selection, for F1's "DAYS" row.
    var daysSummary: String {
        switch selectedDays {
        case Set(1...7): return "Every day"
        case [2, 3, 4, 5, 6]: return "Weekdays"
        case [1, 7]: return "Weekends"
        case []: return "No days"
        default:
            return selectedDays
                .sorted()
                .map { Self.shortDayLabel(weekday: $0) }
                .joined(separator: " · ")
        }
    }

    /// Time formatted for the F1 row, e.g. "08:30".
    var reminderTimeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: reminderTime)
    }

    /// Maps the current `selectedDays` to a `HabitSchedule` + `customDays` pair
    /// for persistence. The model already uses this exact convention.
    var resolvedScheduleAndCustomDays: (HabitSchedule, Set<Int>) {
        switch selectedDays {
        case Set(1...7): return (.daily, [])
        case [2, 3, 4, 5, 6]: return (.weekdays, [])
        case [1, 7]: return (.weekends, [])
        default: return (.custom, selectedDays)
        }
    }

    var canSave: Bool {
        !selectedDays.isEmpty
    }

    // MARK: Init

    init(template: HabitTemplate) {
        self.templateID = template.id
        self.templateName = template.name
        self.templateIcon = template.iconName
        self.templateColorToken = template.colorTokenName
        self.templateCategory = template.category
        self.templateBlurb = template.blurb

        // If template suggests a time, use it; otherwise default to 08:30.
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = template.suggestedHour ?? 8
        comps.minute = template.suggestedMinute ?? 30
        self.reminderTime = Calendar.current.date(from: comps) ?? .now

        // Default to every day. User can untoggle in F3.
        self.selectedDays = Set(1...7)

        // Default on. User toggles off → no permission prompt, no scheduled notifs.
        self.notificationsEnabled = true
    }

    // MARK: Helpers

    static func shortDayLabel(weekday: Int) -> String {
        // 1=Sun … 7=Sat
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
