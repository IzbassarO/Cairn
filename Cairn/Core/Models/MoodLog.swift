import Foundation
import SwiftData

/// One mood entry per day. Captured by the "How's your morning?" selector
/// on the Today screen. A typed wrapper around an `Int` rawValue gives us a
/// stable on-disk encoding even if we reword labels later.
///
/// Why store this at all (vs `@AppStorage`):
///  - **Coach + retention signal**: a sequence of moods over time correlates
///    with adherence. Coach card can adjust tone ("foggy days are when stacks
///    matter most"). Insights tab will show mood-vs-stones overlay.
///  - **Future-proof**: when we add weekly review / streaks, we already have
///    the data. AppStorage would force a painful migration later.
@Model
final class MoodLog {
    var id: UUID = UUID()
    /// The calendar day this mood belongs to (start-of-day in user timezone).
    var day: Date = Date.distantPast
    /// Persisted Int form of `Mood`. Use the `mood` accessor to read/write.
    var moodRaw: Int = MoodValue.okay.rawValue
    /// When the user actually picked it. Useful to distinguish "morning mood
    /// at 7am" from "after-the-fact at 11pm".
    var loggedAt: Date = Date.distantPast

    init(id: UUID = UUID(), day: Date, mood: MoodValue, loggedAt: Date = .now) {
        self.id = id
        self.day = day
        self.moodRaw = mood.rawValue
        self.loggedAt = loggedAt
    }

    var mood: MoodValue {
        get { MoodValue(rawValue: moodRaw) ?? .okay }
        set { moodRaw = newValue.rawValue }
    }
}

/// Mood scale. Order matters (left → right = worse → better). Display labels
/// and SF Symbol icons live in `MoodSelector`; this enum is just data.
enum MoodValue: Int, CaseIterable {
    case foggy = 0
    case off = 1
    case okay = 2
    case good = 3
    case bright = 4

    var label: String {
        switch self {
        case .foggy: return "foggy"
        case .off: return "off"
        case .okay: return "okay"
        case .good: return "good"
        case .bright: return "bright"
        }
    }
}
