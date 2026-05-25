import SwiftUI
import SwiftData

/// Today's habits grouped by time of day (Morning / Afternoon / Evening).
///
/// Replaces the old hourly-grid timeline: with only a handful of habits, a full
/// 18-hour grid left big empty gaps. Grouping fills by content, reads instantly,
/// and keeps the calm feel — while still conveying the shape of the day.
///
/// Read-only — to log or edit, the user goes back to Today.
struct TodayScheduleView: View {
    /// When presented via slideCover (horizontal push), this closes it.
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    private var cal: Calendar { Calendar.current }

    private func close() { if let onClose { onClose() } else { dismiss() } }

    var body: some View {
        VStack(spacing: 0) {
            header
            if entries.isEmpty {
                titleBlock
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        titleBlock
                        ForEach(populatedSections) { section in
                            sectionView(section)
                        }
                    }
                    .padding(.bottom, Spacing.xxl)
                }
                .defaultScrollAnchor(.top)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button(action: close) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Today")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.bgSecondary))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            Spacer()
            Text("Schedule")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Today's")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("rhythm.")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
            statusLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private var eyebrow: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMM d"
        return f.string(from: .now).uppercased()
    }

    private var statusLine: some View {
        let placedCount = entries.filter { $0.state == .completed }.count
        let upcomingCount = entries.filter { $0.state == .upcoming }.count
        let missedCount = entries.filter { $0.state == .missed }.count

        return HStack(spacing: 6) {
            statusPill(label: "\(placedCount) placed", color: Color.accentSage, filled: true)
            statusPill(label: "\(upcomingCount) upcoming", color: Color.accentSage, filled: false)
            if missedCount > 0 {
                statusPill(label: "\(missedCount) missed", color: Color.textTertiary, filled: false)
            }
        }
        .padding(.top, 4)
    }

    private func statusPill(label: String, color: Color, filled: Bool) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(filled ? Color.bgPrimary : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(filled ? color : color.opacity(0.18)))
    }

    // MARK: Section view

    private func sectionView(_ section: DaySection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: section.part.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentSage)
                Text(section.part.title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.textTertiary)
                if section.isNow {
                    Text("NOW")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Color.bgPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentCoral))
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.sm) {
                ForEach(section.entries) { entry in
                    ScheduleHabitCard(
                        habit: entry.habit,
                        reminderTime: entry.reminderTime,
                        state: entry.state
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.accentSage)
            Text("No reminders set for today.")
                .font(.system(size: 15, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
            Text("Habits without a reminder time still live on the Today tab.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Spacer()
            Spacer()
        }
    }

    // MARK: Day parts

    private enum DayPart: Int, CaseIterable {
        case morning, afternoon, evening

        var title: String {
            switch self {
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            }
        }
        var icon: String {
            switch self {
            case .morning: return "sunrise"
            case .afternoon: return "sun.max"
            case .evening: return "moon.stars"
            }
        }
        /// Hour range [start, end). Evening runs to 24.
        var range: Range<Int> {
            switch self {
            case .morning: return 0..<12
            case .afternoon: return 12..<17
            case .evening: return 17..<24
            }
        }
        static func of(hour: Int) -> DayPart {
            switch hour {
            case 0..<12: return .morning
            case 12..<17: return .afternoon
            default: return .evening
            }
        }
    }

    private struct DaySection: Identifiable {
        let part: DayPart
        let entries: [TimelineEntry]
        let isNow: Bool
        var id: Int { part.rawValue }
    }

    /// Only sections that actually have entries, in chronological order.
    private var populatedSections: [DaySection] {
        let nowPart = DayPart.of(hour: cal.component(.hour, from: .now))
        return DayPart.allCases.compactMap { part in
            let inPart = entries
                .filter { part.range.contains(cal.component(.hour, from: $0.reminderTime)) }
                .sorted { $0.reminderTime < $1.reminderTime }
            guard !inPart.isEmpty else { return nil }
            return DaySection(part: part, entries: inPart, isNow: part == nowPart)
        }
    }

    // MARK: Entries — derived

    private var entries: [TimelineEntry] {
        let now = Date.now
        let activeHabits = habits.filter { !$0.isArchived }
        return activeHabits.flatMap { habit -> [TimelineEntry] in
            guard isScheduledToday(habit) else { return [] }
            let projectedTimes = habit.notificationTimes.compactMap { projectToday($0) }
            return projectedTimes.map { projected in
                TimelineEntry(
                    habit: habit,
                    reminderTime: projected,
                    state: classifyState(habit: habit, reminderTime: projected, now: now)
                )
            }
        }
    }

    private func isScheduledToday(_ habit: Habit) -> Bool {
        let weekday = cal.component(.weekday, from: .now)
        switch habit.schedule {
        case .daily: return true
        case .weekdays: return (2...6).contains(weekday)
        case .weekends: return weekday == 1 || weekday == 7
        case .custom: return habit.customDays.contains(weekday)
        }
    }

    private func projectToday(_ time: Date) -> Date? {
        let comps = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(bySettingHour: comps.hour ?? 0,
                        minute: comps.minute ?? 0,
                        second: 0, of: .now)
    }

    private func classifyState(habit: Habit, reminderTime: Date, now: Date) -> ScheduleHabitCard.State {
        if habit.loggedToday { return .completed }
        if reminderTime > now { return .upcoming }
        return .missed
    }
}

/// One entry on the schedule (habit + a single reminder time + its state).
struct TimelineEntry: Identifiable {
    let id = UUID()
    let habit: Habit
    let reminderTime: Date
    let state: ScheduleHabitCard.State
}
