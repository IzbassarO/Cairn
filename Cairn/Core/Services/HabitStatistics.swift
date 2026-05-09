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
        let today = Calendar.current.startOfDay(for: .now)
        return (logs ?? []).contains { Calendar.current.startOfDay(for: $0.loggedAt) == today }
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
