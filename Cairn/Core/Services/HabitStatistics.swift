import Foundation

extension Habit {
    var lifetimeStones: Int {
        logs?.count ?? 0
    }

    var uniqueLogDayCount: Int {
        let cal = Calendar.current
        return Set((logs ?? []).map { cal.startOfDay(for: $0.loggedAt) }).count
    }

    var loggedToday: Bool {
        placedTodayCount > 0
    }

    /// Number of logs placed today. Used both for the daily-cap check and
    /// for showing "2/3" style counters on rows with `targetPerDay > 1`.
    var placedTodayCount: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (logs ?? []).filter { cal.startOfDay(for: $0.loggedAt) == today }.count
    }

    /// True when the habit has been logged its full `targetPerDay` for today.
    /// Drives the "checkmark, disabled" state on Today rows.
    var isFullyPlacedToday: Bool {
        placedTodayCount >= max(1, targetPerDay)
    }

    /// The most recent log placed today, or nil if the habit hasn't been
    /// logged yet today. Used to show "Placed at HH:MM" on the Today row.
    var todayLog: HabitLog? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (logs ?? [])
            .filter { cal.startOfDay(for: $0.loggedAt) == today }
            .sorted { $0.loggedAt > $1.loggedAt }
            .first
    }

    var currentRun: Int {
        StreakCalculator().currentRun(logs ?? [])
    }

    var longestRun: Int {
        StreakCalculator().longestRun(logs ?? [])
    }
}

extension Sequence where Element == Habit {
    var totalStones: Int {
        reduce(0) { $0 + ($1.logs?.count ?? 0) }
    }

    var uniqueLogDayCount: Int {
        let cal = Calendar.current
        let dates = Set(flatMap { ($0.logs ?? []).map { cal.startOfDay(for: $0.loggedAt) } })
        return dates.count
    }
}

enum Greeting {
    static func forCurrentHour(_ now: Date = .now, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Morning."
        case 12..<17: return "Afternoon."
        case 17..<22: return "Evening."
        default: return "Late night."
        }
    }
}
