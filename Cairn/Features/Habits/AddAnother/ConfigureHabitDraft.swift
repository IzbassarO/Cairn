import Foundation
import SwiftUI

/// Mutable draft used by the Configure Habit screen (N2 — add-another flow).
///
/// Functionally similar to `FirstHabitDraft`, with two extensions for the
/// pairing-aware path:
///  - `pairingAnchor`: if non-nil, N2 was opened via a Coach Pairing card.
///    Drives the subtitle ("Coach pairing with X") and the "Stack on existing
///    habit" row in the Notification section.
///  - `cueNote`: auto-generated from the pairing template when applicable,
///    user-editable.
@Observable
final class ConfigureHabitDraft {

    // Source template (read-only — name/icon/category come from here)
    let template: HabitTemplate

    /// Anchor habit if this is a paired flow, else nil.
    let pairingAnchor: Habit?

    // MARK: User-editable
    var reminderTime: Date
    var selectedDays: Set<Int>
    var notificationsEnabled: Bool
    var cueNote: String

    // MARK: Init

    init(template: HabitTemplate, pairingAnchor: Habit? = nil) {
        self.template = template
        self.pairingAnchor = pairingAnchor

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = template.suggestedHour ?? 8
        comps.minute = template.suggestedMinute ?? 30
        self.reminderTime = Calendar.current.date(from: comps) ?? .now

        self.selectedDays = Set(1...7)
        self.notificationsEnabled = true

        // Auto-generate the cue note when the flow has a pairing anchor.
        // Otherwise leave it empty — user can tap to add.
        if let anchor = pairingAnchor {
            self.cueNote = Self.generateCueNote(from: template, anchor: anchor)
        } else {
            self.cueNote = ""
        }
    }

    // MARK: Derived

    /// Header subtitle shown under the habit name. e.g. "Hydration · Coach pairing with Morning meds"
    var subtitle: String {
        let categoryName = friendlyCategoryName
        if let anchor = pairingAnchor {
            return "\(categoryName) · Coach pairing with \(anchor.name)"
        }
        return categoryName
    }

    /// User-facing category name. We don't expose the raw enum string.
    private var friendlyCategoryName: String {
        switch template.category {
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

    /// "30 MIN AFTER MEDS" style hint pill shown next to REMINDER TIME.
    /// Only meaningful when this is a paired flow with an anchor that has
    /// notification times. Returns nil otherwise.
    var reminderHintPill: String? {
        guard let anchor = pairingAnchor,
              let anchorTime = anchor.notificationTimes.first
        else { return nil }
        let minutes = Int(reminderTime.timeIntervalSince(anchorTime) / 60)
        guard minutes != 0 else { return nil }
        let absMinutes = abs(minutes)
        let direction = minutes > 0 ? "AFTER" : "BEFORE"
        let anchorShort = anchor.name.split(separator: " ").last.map(String.init) ?? anchor.name
        return "\(absMinutes) MIN \(direction) \(anchorShort.uppercased())"
    }

    var canSave: Bool {
        !selectedDays.isEmpty
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

    var reminderTimeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: reminderTime)
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

    /// Builds an "After I X, I will Y" cue note for a paired flow.
    /// Reads the anchor's cue field if it has one to make the sentence richer,
    /// otherwise uses the anchor's name verb-style.
    private static func generateCueNote(from template: HabitTemplate, anchor: Habit) -> String {
        let anchorPhrase = anchor.name.lowercased()
        let actionPhrase = templateActionPhrase(template)
        return "\u{201C}After I \(anchorPhrase), I will \(actionPhrase).\u{201D}"
    }

    /// Returns a verb-phrase for the template's action ("pour a glass of water
    /// from the bottle by the sink"). Falls back to the template name lowercased.
    private static func templateActionPhrase(_ template: HabitTemplate) -> String {
        switch template.id {
        case "hydrate":
            return "pour a glass of water from the bottle by the sink"
        case "breath_one_min":
            return "take one minute to breathe before opening email"
        case "move":
            return "move my body for five minutes — walk, stretch, anything"
        case "focus_block":
            return "start one focus block, even if it's short"
        case "wind_down":
            return "dim the lights and put the phone away"
        case "nourish":
            return "eat something, even if it's small"
        default:
            return template.name.lowercased()
        }
    }
}
