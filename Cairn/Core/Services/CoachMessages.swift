import Foundation

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

    static func dailyMessage(activeHabitCount: Int, date: Date = .now) -> String {
        let corpus = activeHabitCount <= 1 ? oneHabitMessages : multiHabitMessages
        return pick(from: corpus, on: date)
    }

    // MARK: - Stone-placed affirmations
    //
    // The "second moment": a brief, calm line shown the instant a stone is
    // placed. Comeback-aware and shame-free — celebrates the act, never scolds.

    enum StoneMoment {
        case milestone(Int)   // crossed 1, 10, 100, 250, 500, 1000
        case dayComplete      // every habit for today is now placed
        case comeback         // this habit was placed after a 2+ day gap
        case firstOfDay       // first stone of the day across all habits
        case placed           // an ordinary placement
    }

    private static let firstOfDayLines = [
        "First stone down. The rest is lighter.",
        "There it is — the day has begun.",
        "One placed. The hardest part is behind you."
    ]

    private static let placedLines = [
        "Placed. The thread holds.",
        "Another stone, quietly stacked.",
        "That counts — every one does.",
        "Steady. This is how cairns rise."
    ]

    private static let comebackLines = [
        "Welcome back. The thread, retied.",
        "You returned — that's the whole skill.",
        "No catching up needed. Just this one."
    ]

    /// A short affirmation for the moment a stone is placed.
    static func affirmation(for moment: StoneMoment) -> String {
        switch moment {
        case .milestone(let n): return "\(n) stones. Look how far you've come."
        case .dayComplete:      return "Every stone placed. Beautiful."
        case .comeback:         return comebackLines.randomElement() ?? "Welcome back."
        case .firstOfDay:       return firstOfDayLines.randomElement() ?? "First stone down."
        case .placed:           return placedLines.randomElement() ?? "Placed."
        }
    }

    private static func pick(from corpus: [String], on date: Date) -> String {
        guard !corpus.isEmpty else { return "" }
        let calendar = Calendar.current
        let referenceDate = Date(timeIntervalSince1970: 0)
        let days = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0
        let index = abs(days) % corpus.count
        return corpus[index]
    }
}
