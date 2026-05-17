import SwiftUI
import SwiftData

/// Full calendar view of every stone placed across all habits. Matches
/// mockup G. Defaults to the current month, with today auto-selected.
///
/// User can navigate prev/next months. Tapping a day reveals the selected-day
/// card at the bottom with that day's logs.
struct GardenView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]

    /// First day (00:00) of the displayed month.
    @State private var displayedMonthStart: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }()

    /// Currently selected day (the bottom card). Auto-set to today on appear
    /// if today is in the displayed month.
    @State private var selectedDay: Date?

    private var cal: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock

                    GardenStatsHero(
                        stones: monthStats.stones,
                        activeDays: monthStats.activeDays,
                        gentleDays: monthStats.gentleDays
                    )

                    GardenCalendarGrid(
                        month: displayedMonthStart,
                        stonesPerDay: stonesPerDay,
                        selectedDay: $selectedDay
                    )

                    GardenIntensityLegend()

                    if let day = selectedDay {
                        GardenSelectedDayCard(
                            date: day,
                            logs: logsForSelectedDay(day)
                        )
                    } else {
                        emptySelectionHint
                    }

                    closingNote
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .onAppear {
            // Auto-select today if it's in the displayed month.
            if selectedDay == nil, cal.isDate(.now, equalTo: displayedMonthStart, toGranularity: .month) {
                selectedDay = cal.startOfDay(for: .now)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .accessibilityLabel("Back to Today")

            Spacer()

            Text("Garden")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Visual placeholder — ··· menu reserved for future actions
            // (Export month, Compare months, etc).
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title

    private var titleBlock: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOU'RE TENDING")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(monthName)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                    Text(yearShort)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.accentSage)
                }
            }
            Spacer()
            navigationChevrons
        }
    }

    private var navigationChevrons: some View {
        HStack(spacing: 8) {
            chevronButton(systemName: "chevron.left", isEnabled: !isAtOrBeforeLowerBound) {
                navigateMonth(by: -1)
            }
            chevronButton(systemName: "chevron.right", isEnabled: !isCurrentOrFutureMonth) {
                navigateMonth(by: 1)
            }
        }
    }

    private func chevronButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isEnabled ? Color.accentSage : Color.textTertiary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }

    // MARK: Empty selection hint + closing note

    private var emptySelectionHint: some View {
        Text("Tap any day to see what you tended.")
            .font(.system(size: 13, design: .serif))
            .italic()
            .foregroundStyle(Color.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
    }

    /// Quiet footer note — sets the tone of the calendar.
    private var closingNote: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 13))
                .foregroundStyle(Color.accentSage)
            Text("Gentle days let the soil rest.")
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.12))
        )
    }

    // MARK: Navigation

    /// True when displayedMonthStart is the current month — disables the
    /// "next" chevron so the user can't browse the future.
    private var isCurrentOrFutureMonth: Bool {
        let thisMonth = cal.dateComponents([.year, .month], from: .now)
        let shown = cal.dateComponents([.year, .month], from: displayedMonthStart)
        if shown.year != thisMonth.year { return (shown.year ?? 0) > (thisMonth.year ?? 0) }
        return (shown.month ?? 0) >= (thisMonth.month ?? 0)
    }

    /// Earliest month the user has any history in. Drives the disable-state
    /// of the "previous" chevron — there's nothing to look at before this.
    ///
    /// Lower bound is computed from two sources, whichever is earlier:
    ///  1. First HabitLog ever recorded
    ///  2. First Habit ever created (covers users who installed but haven't
    ///     placed a stone yet, AND covers archived habits the user kept)
    ///
    /// Falls back to the current month when the user has no history at all —
    /// in that state both chevrons are disabled and the calendar is just
    /// today's empty month.
    private var lowerBoundMonth: Date {
        let activeAndArchived = habits  // @Query returns everything; not filtering by isArchived
        let firstLog = activeAndArchived
            .flatMap { ($0.logs ?? []).filter { $0.modelContext != nil } }
            .map(\.loggedAt)
            .min()
        let firstCreated = activeAndArchived
            .filter { $0.modelContext != nil }
            .map(\.createdAt)
            .min()

        let candidate: Date
        switch (firstLog, firstCreated) {
        case let (l?, c?): candidate = min(l, c)
        case let (l?, nil): candidate = l
        case let (nil, c?): candidate = c
        case (nil, nil):
            // No habits, no logs — pin to current month.
            let comps = cal.dateComponents([.year, .month], from: .now)
            return cal.date(from: comps) ?? .now
        }

        // Snap to start of that month.
        let comps = cal.dateComponents([.year, .month], from: candidate)
        return cal.date(from: comps) ?? candidate
    }

    /// True when we can't go any further back — disables the "previous" chevron.
    private var isAtOrBeforeLowerBound: Bool {
        let shownComps = cal.dateComponents([.year, .month], from: displayedMonthStart)
        let lowerComps = cal.dateComponents([.year, .month], from: lowerBoundMonth)
        if shownComps.year != lowerComps.year {
            return (shownComps.year ?? 0) <= (lowerComps.year ?? 0)
        }
        return (shownComps.month ?? 0) <= (lowerComps.month ?? 0)
    }

    private func navigateMonth(by delta: Int) {
        guard let new = cal.date(byAdding: .month, value: delta, to: displayedMonthStart) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            displayedMonthStart = new
            // Don't carry selection across months — it'd point to a day in
            // the wrong month. If the new month is the current one, snap
            // back to today; otherwise clear.
            if cal.isDate(new, equalTo: .now, toGranularity: .month) {
                selectedDay = cal.startOfDay(for: .now)
            } else {
                selectedDay = nil
            }
        }
    }

    // MARK: Derived — month name / year

    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: displayedMonthStart)
    }

    private var yearShort: String {
        let f = DateFormatter()
        f.dateFormat = "yy"
        return "'\(f.string(from: displayedMonthStart))"
    }

    // MARK: Derived — stones per day for the displayed month

    private var allLogs: [HabitLog] {
        habits
            .filter { !$0.isArchived }
            .flatMap { ($0.logs ?? []).filter { $0.modelContext != nil } }
    }

    /// Map of day → number of unique habits placed that day. We dedupe at
    /// the habit level (a habit logged 3 times still counts as 1 toward
    /// that day's "stones placed" — matches the language elsewhere in the app).
    private var stonesPerDay: [Date: Int] {
        // Restrict to logs within the displayed month for performance.
        let monthEnd = cal.date(byAdding: .month, value: 1, to: displayedMonthStart) ?? displayedMonthStart

        var bucket: [Date: Set<UUID>] = [:]
        for log in allLogs {
            let day = cal.startOfDay(for: log.loggedAt)
            guard day >= displayedMonthStart && day < monthEnd else { continue }
            guard let habit = log.habit else { continue }
            bucket[day, default: []].insert(habit.id)
        }
        return bucket.mapValues { $0.count }
    }

    // MARK: Derived — monthly stats

    private struct MonthStats {
        let stones: Int
        let activeDays: Int
        let gentleDays: Int
    }

    /// `stones` = total unique habit-days this month (sum of stonesPerDay).
    /// `activeDays` = days with at least one stone.
    /// `gentleDays` = past days in the month (up to today) with zero stones.
    ///                Future days are not "gentle" — they just haven't happened.
    private var monthStats: MonthStats {
        let today = cal.startOfDay(for: .now)
        let monthEnd = cal.date(byAdding: .month, value: 1, to: displayedMonthStart) ?? displayedMonthStart
        // The last day we count toward gentle = min(today, last day of month)
        let effectiveEnd = min(today, cal.date(byAdding: .day, value: -1, to: monthEnd) ?? today)

        let stones = stonesPerDay.values.reduce(0, +)
        let activeDays = stonesPerDay.values.filter { $0 > 0 }.count

        // Count gentle days: iterate days from monthStart to effectiveEnd.
        var gentle = 0
        var cursor = displayedMonthStart
        while cursor <= effectiveEnd {
            let placed = stonesPerDay[cursor] ?? 0
            if placed == 0 {
                gentle += 1
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return MonthStats(stones: stones, activeDays: activeDays, gentleDays: gentle)
    }

    // MARK: Selected-day logs

    /// Logs that fell on the selected day, sorted by time.
    /// `habitName` is resolved via `log.habit` — if the habit was deleted
    /// since, we use a fallback "(deleted)".
    private func logsForSelectedDay(_ day: Date) -> [(habitName: String, loggedAt: Date)] {
        allLogs
            .filter { cal.isDate($0.loggedAt, inSameDayAs: day) }
            .sorted { $0.loggedAt < $1.loggedAt }
            .map { log in
                (log.habit?.name ?? "(deleted)", log.loggedAt)
            }
    }
}
