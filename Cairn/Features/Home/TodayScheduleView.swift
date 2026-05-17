import SwiftUI
import SwiftData

/// Day-View timeline of today's habits. Opens from the calendar icon in the
/// Today header.
///
/// Each habit's reminder times become entries on a vertical hourly grid. Cards
/// are coloured by state (completed / upcoming / missed). Read-only — to log
/// or edit, the user goes back to Today.
struct TodayScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    private var cal: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 0) {
            header
            titleBlock
            if entries.isEmpty {
                emptyState
            } else {
                HourlyTimelineGrid(entries: entries, showsCurrentTime: true)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
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
                    Text("Today")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }

            Spacer()

            Text("Schedule")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Spacer to keep title centered.
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
            .foregroundStyle(filled ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(filled ? color : color.opacity(0.18))
            )
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

    // MARK: Entries — derived

    /// One entry per (habit, reminder time) pair that's scheduled today.
    /// Multi-target habits with 3 reminder times produce 3 entries.
    /// Habits with no notification times don't appear.
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

    /// True if `habit.schedule` includes today's weekday.
    private func isScheduledToday(_ habit: Habit) -> Bool {
        let weekday = cal.component(.weekday, from: .now)
        switch habit.schedule {
        case .daily: return true
        case .weekdays: return (2...6).contains(weekday)
        case .weekends: return weekday == 1 || weekday == 7
        case .custom: return habit.customDays.contains(weekday)
        }
    }

    /// Project a stored notification time (year/month/day from when it was
    /// set) onto today.
    private func projectToday(_ time: Date) -> Date? {
        let comps = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(bySettingHour: comps.hour ?? 0,
                        minute: comps.minute ?? 0,
                        second: 0, of: .now)
    }

    /// Classify a single (habit, time) pair:
    ///  - `completed`: any log for this habit today (we don't link individual
    ///    logs to individual reminder slots — that's correct UX, a 9am
    ///    reminder counts as fulfilled if user logged at 9:30)
    ///  - `upcoming`: reminder time in the future
    ///  - `missed`: reminder time in the past, no log today
    private func classifyState(habit: Habit, reminderTime: Date, now: Date) -> ScheduleHabitCard.State {
        if habit.loggedToday { return .completed }
        if reminderTime > now { return .upcoming }
        return .missed
    }
}
