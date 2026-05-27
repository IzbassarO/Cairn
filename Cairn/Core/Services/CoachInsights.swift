import Foundation

// MARK: - CoachInsights
struct CoachInsights {
    let habits: [Habit]
    var calendar: Calendar = .current
    var now: Date = .now

    /// All non-archived logs, flattened.
    private var allLogs: [HabitLog] {
        habits.filter { !$0.isArchived }.flatMap { $0.logs ?? [] }
    }

    private var totalStones: Int { allLogs.count }

    /// Distinct days the user placed at least one stone.
    private var activeDayCount: Int {
        Set(allLogs.map { calendar.startOfDay(for: $0.loggedAt) }).count
    }

    // MARK: Readiness

    static let minimumStonesForInsights = 12

    var hasEnoughData: Bool { totalStones >= Self.minimumStonesForInsights }

    /// How close the user is to unlocking insights (0...1), for the empty state.
    var warmupProgress: Double {
        min(1, Double(totalStones) / Double(Self.minimumStonesForInsights))
    }

    var stonesUntilInsights: Int {
        max(0, Self.minimumStonesForInsights - totalStones)
    }

    // MARK: Best weekday

    struct WeekdayInsight {
        let weekdaySymbol: String      // "Monday"
        let shortSymbols: [String]     // ["M","T","W"...] Mon-first
        let perWeekdayCounts: [Int]    // counts aligned to shortSymbols
        let bestIndex: Int             // index into the arrays
        let sharePercent: Int          // % of stones on that weekday
    }

    /// The weekday the user places the most stones on. Needs enough spread
    /// (stones across several days) before it means anything.
    var bestWeekday: WeekdayInsight? {
        guard hasEnoughData, activeDayCount >= 5 else { return nil }

        // Monday-first buckets (Calendar weekday: 1=Sun…7=Sat).
        var counts = Array(repeating: 0, count: 7)
        for log in allLogs {
            let wd = calendar.component(.weekday, from: log.loggedAt) // 1...7
            let mondayFirst = (wd + 5) % 7                            // Mon=0…Sun=6
            counts[mondayFirst] += 1
        }
        guard let best = counts.indices.max(by: { counts[$0] < counts[$1] }),
              counts[best] > 0 else { return nil }

        // Require the best day to actually stand out (not a flat tie).
        let total = counts.reduce(0, +)
        let share = Int((Double(counts[best]) / Double(total) * 100).rounded())
        guard share >= 20 else { return nil }  // 1/7 ≈ 14%; 20%+ = real lean

        let fullNames = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        return WeekdayInsight(
            weekdaySymbol: fullNames[best],
            shortSymbols: ["M","T","W","T","F","S","S"],
            perWeekdayCounts: counts,
            bestIndex: best,
            sharePercent: share
        )
    }

    // MARK: Best time of day

    struct TimeOfDayInsight {
        let label: String        // "Mornings"
        let detail: String       // "before 10am"
        let sharePercent: Int
        let hourBuckets: [Int]   // 24 counts, for the mini bar chart
        let peakHour: Int
    }

    var bestTimeOfDay: TimeOfDayInsight? {
        guard hasEnoughData else { return nil }

        var hours = Array(repeating: 0, count: 24)
        for log in allLogs {
            hours[calendar.component(.hour, from: log.loggedAt)] += 1
        }
        let total = hours.reduce(0, +)
        guard total > 0 else { return nil }
        guard let peak = hours.indices.max(by: { hours[$0] < hours[$1] }) else { return nil }

        // Window definitions (start...end exclusive).
        let windows: [(label: String, detail: String, range: Range<Int>)] = [
            ("Mornings", "before noon", 5..<12),
            ("Afternoons", "midday", 12..<17),
            ("Evenings", "after 5pm", 17..<23),
            ("Late nights", "after dark", 23..<24)
        ]
        let window = windows.first { $0.range.contains(peak) }
            ?? ("Mornings", "early", 5..<12)
        let inWindow = window.range.reduce(0) { $0 + hours[$1] }
        let share = Int((Double(inWindow) / Double(total) * 100).rounded())
        guard share >= 35 else { return nil }  // needs a real concentration

        return TimeOfDayInsight(
            label: window.label,
            detail: window.detail,
            sharePercent: share,
            hourBuckets: hours,
            peakHour: peak
        )
    }

    // MARK: Habit health

    enum HealthTrend {
        case rockSolid     // ≥ 85%
        case steady        // 60–84%
        case slipping      // < 60%
    }

    struct HabitHealth: Identifiable {
        let id: UUID
        let name: String
        let iconName: String
        let completionPercent: Int   // last-30-day adherence
        let trend: HealthTrend
    }

    /// Per-habit adherence over the last 30 scheduled days. Only habits old
    /// enough to judge (≥ 7 days since creation) are included.
    var habitHealth: [HabitHealth] {
        guard hasEnoughData else { return [] }
        let active = habits.filter { !$0.isArchived }
        let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        return active.compactMap { habit in
            let ageDays = calendar.dateComponents([.day], from: habit.createdAt, to: now).day ?? 0
            guard ageDays >= 7 else { return nil }

            // Days in the window the habit existed for.
            let windowStart = max(habit.createdAt, cutoff)
            let possibleDays = max(1, calendar.dateComponents([.day], from: windowStart, to: now).day ?? 1)
            let placedDays = Set(
                (habit.logs ?? [])
                    .filter { $0.loggedAt >= windowStart }
                    .map { calendar.startOfDay(for: $0.loggedAt) }
            ).count

            let pct = min(100, Int((Double(placedDays) / Double(possibleDays) * 100).rounded()))
            let trend: HealthTrend = pct >= 85 ? .rockSolid : (pct >= 60 ? .steady : .slipping)
            return HabitHealth(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                completionPercent: pct,
                trend: trend
            )
        }
        .sorted { $0.completionPercent > $1.completionPercent }
    }

    // MARK: Headline

    /// One-line summary for the top of the screen, always safe to show.
    var headline: String {
        if !hasEnoughData {
            return "Still gathering your patterns."
        }
        if let day = bestWeekday {
            return "You're strongest on \(day.weekdaySymbol)s."
        }
        if let time = bestTimeOfDay {
            return "\(time.label) are your hour."
        }
        return "Your rhythm is taking shape."
    }
}
