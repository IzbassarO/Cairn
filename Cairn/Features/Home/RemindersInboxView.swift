import SwiftUI
import SwiftData

/// Inbox-style view of recent reminders.
///
/// What it shows:
///  - Every habit + reminder time that was scheduled to fire in the last 30 days
///  - Classified as `delivered & completed` (sage check) or `delivered & missed`
///    (faded) based on whether the habit was logged that day
///  - Grouped by day, newest first: Today, Yesterday, Mon Nov 11, ...
///
/// What it does NOT show:
///  - Actual iOS-delivered notifications (Apple doesn't expose this)
///  - Anything older than 30 days (auto-cleanup window — data stays in DB,
///    just filtered out of the UI)
///
/// Why synthetic: we don't track real notification deliveries (yet). For the
/// user this is equivalent — "the app remembers when it would have nudged me
/// and whether I followed through". When we add real delivery tracking later,
/// this view can layer real data on top of the synthetic baseline.
struct RemindersInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    /// Auto-cleanup window. Reminders older than this many days are not shown.
    /// The data isn't deleted from SwiftData — habit logs stay intact — we
    /// just filter at render time so the inbox doesn't grow unbounded.
    private let visibilityWindowDays: Int = 30

    private var cal: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock
                    if grouped.isEmpty {
                        emptyState
                    } else {
                        ForEach(grouped, id: \.day) { group in
                            daySection(group)
                        }
                        footerNote
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
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

            Text("Reminders")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrowLine)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
            Text(headlineLine)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
        }
    }

    private var eyebrowLine: String {
        "LAST \(visibilityWindowDays) DAYS"
    }

    private var headlineLine: String {
        let total = grouped.reduce(0) { $0 + $1.entries.count }
        let completed = grouped.reduce(0) { acc, group in
            acc + group.entries.filter { $0.state == .completed }.count
        }
        if total == 0 { return "Nothing here yet." }
        return "\(completed) of \(total) followed through."
    }

    // MARK: Day section

    private func daySection(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayLabel(group.day))
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(daySummary(group))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(0.8)
            }
            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { idx, entry in
                    inboxRow(entry)
                    if idx < group.entries.count - 1 {
                        Divider().overlay(Color.bgTertiary).padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private func inboxRow(_ entry: InboxEntry) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(entry.state == .completed ? Color.accentSage : Color.bgTertiary)
                Image(systemName: entry.state == .completed ? "checkmark" : entry.habitIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(entry.state == .completed ? .white : Color.textTertiary)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(entry.state == .completed ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(entry.state == .completed, color: Color.textSecondary.opacity(0.5))
                Text(rowSubtitle(entry))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer(minLength: 0)

            Text(timeString(entry.scheduledAt))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
    }

    private func rowSubtitle(_ entry: InboxEntry) -> String {
        switch entry.state {
        case .completed:
            if let logged = entry.completedAt {
                return "Followed through at \(timeString(logged))"
            }
            return "Followed through"
        case .missed: return "No stone placed"
        case .upcoming: return "Scheduled"
        }
    }

    private func daySummary(_ group: DayGroup) -> String {
        let completed = group.entries.filter { $0.state == .completed }.count
        let total = group.entries.count
        return "\(completed)/\(total)"
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "bell.slash")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Color.accentSage)
            Text("No reminders yet.")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
            Text("As you build habits with reminder times, they'll show up here.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: Footer

    private var footerNote: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
            Text("Reminders older than \(visibilityWindowDays) days clear automatically.")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.top, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Data model

    /// One row in the inbox. State is derived at render time from logs +
    /// reminder schedule.
    private struct InboxEntry: Identifiable {
        let id: String        // stable: habitID + scheduledAt timestamp
        let habitName: String
        let habitIcon: String
        let scheduledAt: Date
        let state: ScheduleHabitCard.State
        let completedAt: Date?
    }

    private struct DayGroup {
        let day: Date         // startOfDay
        let entries: [InboxEntry]
    }

    // MARK: Derive entries

    /// Walk back `visibilityWindowDays` days. For each day, for each active
    /// habit scheduled that weekday with at least one notification time,
    /// produce one entry per reminder.
    private var grouped: [DayGroup] {
        let now = Date.now
        let today = cal.startOfDay(for: now)
        guard let windowStart = cal.date(byAdding: .day, value: -visibilityWindowDays, to: today) else {
            return []
        }

        let activeHabits = habits.filter { !$0.isArchived }

        var byDay: [Date: [InboxEntry]] = [:]
        var cursor = windowStart
        while cursor <= today {
            let dayStart = cal.startOfDay(for: cursor)
            let weekday = cal.component(.weekday, from: dayStart)

            for habit in activeHabits {
                guard !habit.notificationTimes.isEmpty else { continue }
                guard isScheduledOn(weekday: weekday, habit: habit) else { continue }
                // Skip days before the habit existed.
                if dayStart < cal.startOfDay(for: habit.createdAt) { continue }

                let placedOnDay: HabitLog? = (habit.logs ?? [])
                    .filter { $0.modelContext != nil }
                    .first { cal.isDate($0.loggedAt, inSameDayAs: dayStart) }

                for storedTime in habit.notificationTimes {
                    let projected = projectOnto(dayStart: dayStart, time: storedTime)

                    let state: ScheduleHabitCard.State
                    if projected > now {
                        // Future today — happens for cursor==today with a
                        // late-evening reminder.
                        state = .upcoming
                    } else if placedOnDay != nil {
                        state = .completed
                    } else {
                        state = .missed
                    }

                    let entryID = "\(habit.id.uuidString)-\(Int(projected.timeIntervalSince1970))"
                    let entry = InboxEntry(
                        id: entryID,
                        habitName: habit.name,
                        habitIcon: habit.iconName,
                        scheduledAt: projected,
                        state: state,
                        completedAt: state == .completed ? placedOnDay?.loggedAt : nil
                    )
                    byDay[dayStart, default: []].append(entry)
                }
            }

            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        // Sort: newest day first, within a day newest reminder first.
        return byDay
            .map { day, entries in
                DayGroup(day: day, entries: entries.sorted { $0.scheduledAt > $1.scheduledAt })
            }
            .sorted { $0.day > $1.day }
    }

    private func isScheduledOn(weekday: Int, habit: Habit) -> Bool {
        switch habit.schedule {
        case .daily: return true
        case .weekdays: return (2...6).contains(weekday)
        case .weekends: return weekday == 1 || weekday == 7
        case .custom: return habit.customDays.contains(weekday)
        }
    }

    private func projectOnto(dayStart: Date, time: Date) -> Date {
        let comps = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(bySettingHour: comps.hour ?? 0,
                        minute: comps.minute ?? 0,
                        second: 0, of: dayStart) ?? dayStart
    }

    // MARK: Date formatting

    private func dayLabel(_ date: Date) -> String {
        let today = cal.startOfDay(for: .now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        if cal.isDate(date, inSameDayAs: today) { return "Today" }
        if cal.isDate(date, inSameDayAs: yesterday) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
