import Foundation

/// Returns coach copy for the Today screen. The selection is deterministic
/// from the calendar date — same message all day, rotates at midnight.
///
/// Two corpora live here:
///  - `oneHabitMessages` — when the user has exactly one active habit.
///    Tone: gentle, observational, low-pressure. The coach is "watching quietly".
///  - `multiHabitMessages` — when the user has 2+ active habits.
///    Tone: momentum, pairing, identity. The coach is "noticing patterns".
///
/// Add to either array freely; nothing else changes.
enum CoachMessages {

    static let oneHabitMessages: [String] = [
        "One habit is the perfect ceiling for week one. I'll watch quietly for 5 days before I say anything else.",
        "Starting with one is the most underrated move. Small surface area, big signal.",
        "I'm not going to nudge you about doing more. One habit, done consistently, beats five attempted halfway.",
        "Week one is for noticing what gets in the way — not for piling on. I'll be here.",
        "You don't need another habit yet. You need this one to feel like yours.",
        "Tiny anchors hold the biggest ships. Keep going with just this for now.",
        "The first habit teaches you what time of day actually works. Let it.",
        "I'll learn your patterns this week. Nothing to do but show up when you can."
    ]

    static let multiHabitMessages: [String] = [
        "Nice pairing. Stacking on an existing routine has 2× the stick-rate.",
        "Water on top of meds is one of the stickiest combos I know — same trigger, same time, half the work.",
        "When you place two stones close in time, the second one rides the first one's momentum. That's the whole trick.",
        "Pairing is the cheat code for ADHD habits. The cue is already there — you just stacked on top.",
        "Two habits, one cue. This is the structure that actually compounds.",
        "I'm watching how these two relate. Sometimes the order matters more than the time.",
        "If one of them is slipping, look at the other — they share a trigger now, for better or worse.",
        "The second habit is where you start to feel like 'someone who does this'. Keep going."
    ]

    /// Pick a message for the current day, based on how many active habits exist.
    static func dailyMessage(activeHabitCount: Int, date: Date = .now) -> String {
        let corpus = activeHabitCount <= 1 ? oneHabitMessages : multiHabitMessages
        return pick(from: corpus, on: date)
    }

    /// Deterministic pick: same date → same index, regardless of how many
    /// times we call this in a day. Rotates at local midnight.
    private static func pick(from corpus: [String], on date: Date) -> String {
        guard !corpus.isEmpty else { return "" }
        // Use day-of-era so the index advances by exactly 1 per calendar day.
        // (Hash-of-startOfDay would also work but isn't stable across launches.)
        let calendar = Calendar.current
        let referenceDate = Date(timeIntervalSince1970: 0)
        let days = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0
        let index = abs(days) % corpus.count
        return corpus[index]
    }
}
