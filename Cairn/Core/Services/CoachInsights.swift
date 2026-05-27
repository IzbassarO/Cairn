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
        /// Last 14 calendar days, oldest→newest. true = a stone was placed
        /// that day. Drives the stone-dot sparkline (replaces a progress bar).
        let dots: [Bool]
    }

    /// Per-habit adherence over the last 30 days. Only habits old enough to
    /// judge (≥ 7 days since creation) are included.
    var habitHealth: [HabitHealth] {
        let active = habits.filter { !$0.isArchived }
        let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let today = calendar.startOfDay(for: now)

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

            var dots: [Bool] = []
            for i in (0..<14).reversed() {
                let day = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                let placed = (habit.logs ?? []).contains { calendar.isDate($0.loggedAt, inSameDayAs: day) }
                dots.append(placed)
            }

            return HabitHealth(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                completionPercent: pct,
                trend: trend,
                dots: dots
            )
        }
        .sorted { $0.completionPercent > $1.completionPercent }
    }

    // MARK: Runs & comebacks (the "returns" framing)

    /// Unique calendar days with at least one stone, across all active habits,
    /// sorted oldest→newest.
    private var activeDays: [Date] {
        Set(allLogs.map { calendar.startOfDay(for: $0.loggedAt) }).sorted()
    }

    /// Lifetime stones, exposed for stat cards.
    var lifetimeStones: Int { totalStones }

    /// Consecutive days (any habit) ending today/yesterday with a stone.
    var currentRunDays: Int {
        StreakCalculator(calendar: calendar, now: { now }).currentRun(allLogs)
    }

    var longestRunDays: Int {
        StreakCalculator(calendar: calendar, now: { now }).longestRun(allLogs)
    }

    /// A "comeback" = returning to a habit after missing one or more days.
    /// Counted per habit as the number of gaps (> 1 day) between consecutive
    /// placement days, summed across habits. Celebrates returns rather than
    /// punishing breaks — the heart of Cairn's shame-free promise.
    var comebackCount: Int {
        habits.filter { !$0.isArchived }.reduce(0) { total, habit in
            let days = Set((habit.logs ?? []).map { calendar.startOfDay(for: $0.loggedAt) }).sorted()
            guard days.count >= 2 else { return total }
            let returns = (1..<days.count).reduce(0) { acc, i in
                let gap = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 1
                return acc + (gap > 1 ? 1 : 0)
            }
            return total + returns
        }
    }

    /// Stones placed in the last 7 days.
    var weekStones: Int {
        let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        return allLogs.filter { $0.loggedAt >= weekStart }.count
    }

    /// If the user placed a stone today or yesterday that ended a gap, returns
    /// the size of that gap — used to celebrate a fresh comeback.
    private var recentReturnGap: Int? {
        let today = calendar.startOfDay(for: now)
        let days = activeDays
        guard days.count >= 2, let last = days.last else { return nil }
        let sinceLast = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        guard sinceLast <= 1 else { return nil }
        let prev = days[days.count - 2]
        let gap = calendar.dateComponents([.day], from: prev, to: last).day ?? 1
        return gap > 1 ? gap : nil
    }

    private struct Lapse {
        let name: String
        let days: Int
    }

    /// The habit that had real momentum (≥ 3 placements) but hasn't been placed
    /// in a couple of days — the best candidate for a gentle return nudge.
    private var mostNotableLapse: Lapse? {
        let today = calendar.startOfDay(for: now)
        var best: Lapse?
        for habit in habits.filter({ !$0.isArchived }) {
            let logDays = (habit.logs ?? []).map { calendar.startOfDay(for: $0.loggedAt) }
            guard Set(logDays).count >= 3, let last = logDays.max() else { continue }
            let gap = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            guard gap >= 2 else { continue }
            if best == nil || gap > best!.days {
                best = Lapse(name: habit.name, days: gap)
            }
        }
        return best
    }

    // MARK: Category breakdown

    struct CategoryShare: Identifiable {
        let id: Int          // category rawValue
        let name: String
        let iconName: String
        let stones: Int
        let percent: Int
    }

    /// Where the user's stones go, by category — the top areas only (a long
    /// flat list isn't a useful read). Each carries its share of all stones.
    /// Empty when fewer than two categories have stones (nothing to compare).
    var categoryBreakdown: [CategoryShare] {
        var counts: [Int: Int] = [:]   // categoryRaw -> stones
        for habit in habits where !habit.isArchived {
            counts[habit.categoryRaw, default: 0] += (habit.logs?.count ?? 0)
        }
        let withStones = counts.filter { $0.value > 0 }
        let total = withStones.values.reduce(0, +)
        guard withStones.count >= 2, total > 0 else { return [] }

        return withStones
            .map { raw, stones -> CategoryShare in
                let cat = HabitCategory(rawValue: raw) ?? .custom
                let pct = Int((Double(stones) / Double(total) * 100).rounded())
                return CategoryShare(id: raw, name: cat.displayName,
                                     iconName: cat.defaultIcon, stones: stones, percent: pct)
            }
            .sorted { $0.stones > $1.stones }
            .prefix(4)
            .map { $0 }
    }

    // MARK: Momentum over time (for the interactive chart)

    enum TrendPeriod: String, CaseIterable, Identifiable {
        case week, month, halfYear
        var id: String { rawValue }
        var label: String {
            switch self {
            case .week:     return "Week"
            case .month:    return "Month"
            case .halfYear: return "6 Months"
            }
        }
        /// Caption used under the headline (reads naturally after "this/the").
        var caption: String {
            switch self {
            case .week:     return "past week"
            case .month:    return "past 5 weeks"
            case .halfYear: return "past 6 months"
            }
        }
    }

    struct TrendPoint: Identifiable {
        let id = UUID()
        let label: String   // unique within a series (safe as a Chart x value)
        let stones: Int
    }

    /// Stones bucketed over time for the chosen period. Buckets are unique by
    /// label within each period, oldest→newest. Drives the momentum chart.
    func momentumSeries(_ period: TrendPeriod) -> [TrendPoint] {
        let cal = calendar
        let today = cal.startOfDay(for: now)

        func count(from lo: Date, before hi: Date) -> Int {
            allLogs.filter { $0.loggedAt >= lo && $0.loggedAt < hi }.count
        }

        switch period {
        case .week:
            let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return (0..<7).reversed().compactMap { i in
                guard let day = cal.date(byAdding: .day, value: -i, to: today) else { return nil }
                let stones = allLogs.filter { cal.isDate($0.loggedAt, inSameDayAs: day) }.count
                let wd = cal.component(.weekday, from: day) // 1...7
                return TrendPoint(label: symbols[wd - 1], stones: stones)
            }
        case .month:
            return (0..<5).reversed().compactMap { w in
                guard let anchor = cal.date(byAdding: .day, value: -7 * w, to: today),
                      let windowStart = cal.date(byAdding: .day, value: -6, to: anchor),
                      let hi = cal.date(byAdding: .day, value: 1, to: anchor) else { return nil }
                let stones = count(from: cal.startOfDay(for: windowStart), before: cal.startOfDay(for: hi))
                let label = w == 0 ? "Now" : "\(w)w"   // "Now", "1w", "2w"… (unique)
                return TrendPoint(label: label, stones: stones)
            }
        case .halfYear:
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"
            return (0..<6).reversed().compactMap { m in
                guard let monthDate = cal.date(byAdding: .month, value: -m, to: today),
                      let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)),
                      let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
                let stones = count(from: monthStart, before: monthEnd)
                return TrendPoint(label: fmt.string(from: monthStart), stones: stones)
            }
        }
    }

    // MARK: Today's read (the guide)

    /// A single, data-reactive coaching message for the top of the screen.
    /// Always returns something. Prioritizes comeback framing: celebrating
    /// returns and gently inviting lapsed habits back, never guilt.
    struct Guidance {
        let eyebrow: String
        let icon: String
        let title: String
        let body: String
    }

    var todaysGuidance: Guidance {
        if totalStones == 0 {
            return Guidance(
                eyebrow: "TODAY'S READ", icon: "leaf",
                title: "Place your first stone.",
                body: "Whenever you're ready. From your first one, I start learning when and how you show up."
            )
        }
        if let gap = recentReturnGap {
            return Guidance(
                eyebrow: "WELCOME BACK", icon: "arrow.uturn.backward",
                title: "You came back.",
                body: "After \(gap) days away, you placed a stone again. Returning is the real skill — not never missing. That's a comeback."
            )
        }
        if let lapse = mostNotableLapse {
            return Guidance(
                eyebrow: "A GENTLE NUDGE", icon: "leaf",
                title: "\(lapse.name) is waiting.",
                body: "It's been \(lapse.days) days. No need to catch up or make up for it — the next stone is the only one that counts."
            )
        }
        if currentRunDays >= 3 {
            return Guidance(
                eyebrow: "TODAY'S READ", icon: "leaf.fill",
                title: "\(currentRunDays) days, unbroken.",
                body: "You're in a rhythm. Protect it gently — even one small stone keeps the thread going."
            )
        }
        if comebackCount >= 2 {
            return Guidance(
                eyebrow: "TODAY'S READ", icon: "arrow.uturn.backward",
                title: "You're someone who returns.",
                body: "You've come back \(comebackCount) times after a break. That resilience outlasts any streak."
            )
        }
        return Guidance(
            eyebrow: "TODAY'S READ", icon: "leaf",
            title: "One stone at a time.",
            body: "Every placement teaches me your rhythm. Show up when you can — that's all this asks."
        )
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
