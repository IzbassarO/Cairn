import Foundation

struct StreakCalculator {
    private let calendar: Calendar
    private let now: () -> Date

    init(calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.now = now
    }

    func lifetimeStones(_ logs: [HabitLog]) -> Int {
        logs.count
    }

    func currentRun(_ logs: [HabitLog]) -> Int {
        let sortedDays = uniqueLogDays(logs).sorted(by: >)
        guard let mostRecent = sortedDays.first else { return 0 }

        let today = calendar.startOfDay(for: now())
        let hoursSinceMostRecent = now().timeIntervalSince(mostRecent) / 3600
        if hoursSinceMostRecent > 48 { return 0 }

        var run = 0
        var cursor = today
        for day in sortedDays {
            while cursor > day {
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            }
            if day == cursor {
                run += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else {
                break
            }
        }
        return run
    }

    func longestRun(_ logs: [HabitLog]) -> Int {
        let days = uniqueLogDays(logs).sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<days.count {
            let prev = days[i - 1]
            let day = days[i]
            if calendar.dateComponents([.day], from: prev, to: day).day == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    private func uniqueLogDays(_ logs: [HabitLog]) -> Set<Date> {
        Set(logs.map { calendar.startOfDay(for: $0.loggedAt) })
    }
}
