import SwiftUI
import SwiftData

/// Full-screen info & stats screen for a single habit. Layout from mockup 05.
///
/// Flow:
///  - Opens from `TodayHabitRow` when the user taps the row outside the circle.
///  - Top-right `···` menu offers Edit (opens `HabitEditView`) and Delete
///    (CairnAlert confirmation, then closes this view and deletes the habit).
///  - The screen reads from the live `Habit` reactively — once Edit applies,
///    fields refresh automatically.
struct HabitInfoView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showHistory = false

    private var service: HabitService { HabitService(context: context) }

    var body: some View {
        // Defensive guard: if the habit was deleted while this view is on
        // screen, SwiftData detaches its modelContext. Render a blank cover
        // until the dismiss completes, never read habit.* in that state.
        Group {
            if habit.modelContext != nil {
                content
            } else {
                Color.bgPrimary.ignoresSafeArea()
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .fullScreenCover(isPresented: $showEdit) {
            if habit.modelContext != nil {
                HabitEditView(habit: habit)
            }
        }
        .fullScreenCover(isPresented: $showHistory) {
            if habit.modelContext != nil {
                HabitHistoryView(habit: habit)
            }
        }
        .cairnAlert(
            isPresented: $showDeleteConfirm,
            title: "Delete this habit?",
            message: deleteAlertMessage,
            confirmTitle: "Delete",
            confirmRole: .destructive,
            cancelTitle: "Cancel",
            onConfirm: { performDelete() }
        )
    }

    /// Quoted habit name + stone count, matching mockup A.
    /// e.g. `"Drink water" and its 24 stones will be removed. This can't be undone.`
    private var deleteAlertMessage: String {
        guard habit.modelContext != nil else {
            return "This habit will be removed. This can't be undone."
        }
        let stones = (habit.logs ?? []).filter { $0.modelContext != nil }.count
        let stonePhrase: String
        switch stones {
        case 0: return "\u{201C}\(habit.name)\u{201D} will be removed. This can't be undone."
        case 1: stonePhrase = "1 stone"
        default: stonePhrase = "\(stones) stones"
        }
        return "\u{201C}\(habit.name)\u{201D} and its \(stonePhrase) will be removed. This can't be undone."
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock
                    cueLineIfAny
                    stonesPlacedCard
                    HabitHeatmapGrid(habit: habit)
                    scheduleSection
                    historySection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
    }

    // MARK: Header (back + ···)

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
            .accessibilityLabel("Back to Today")

            Spacer()

            Menu {
                Button {
                    showEdit = true
                } label: {
                    Label("Edit habit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete habit", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title block

    private var titleBlock: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.accentSage.opacity(0.18))
                Image(systemName: habit.iconName)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(friendlyCategoryName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                Text(habit.name)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var cueLineIfAny: some View {
        if !habit.cueNote.isEmpty {
            Text(habit.cueNote)
                .font(.system(size: 15, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Stones placed card

    private var stonesPlacedCard: some View {
        // Header counter and progress bar are scoped to "this month" — gives
        // a meaningful denominator (vs lifetime stones, which has no ceiling
        // and so can't form a percentage).
        let stats = monthStats
        return HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text("STONES PLACED")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(stats.placed)")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                    Text("of \(stats.scheduled)")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.accentSage)
                }

                HStack(spacing: 4) {
                    Text(daysCountText(stats.placed))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                    Text("this month,")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                    Text("growing.")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Color.accentSage)
                }

                progressBar(fraction: stats.fraction)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)

            // Static small stone visual.
            StoneView(tint: .stoneFill, width: 72)
                .padding(.trailing, 4)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func progressBar(fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.accentSage.opacity(0.18))
                Capsule().fill(Color.accentSage)
                    .frame(width: geo.size.width * CGFloat(fraction))
                    .animation(.spring(response: 0.55, dampingFraction: 0.78),
                               value: fraction)
            }
        }
        .frame(height: 6)
    }

    // MARK: Schedule section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SCHEDULE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                scheduleRow(
                    icon: "clock",
                    label: "Reminder time",
                    value: reminderTimeText
                )
                divider
                scheduleRow(
                    icon: "calendar",
                    label: "Days",
                    value: daysText
                )
                divider
                scheduleRow(
                    icon: "leaf",
                    label: "Category",
                    value: friendlyCategoryName
                )
                if habit.targetPerDay > 1 {
                    divider
                    scheduleRow(
                        icon: "repeat",
                        label: "Times per day",
                        value: "\(habit.targetPerDay)"
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private var divider: some View {
        Divider().overlay(Color.bgTertiary).padding(.leading, 72)
    }

    private func scheduleRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.md) {
            iconTile(systemName: icon)
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }

    private func iconTile(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentSage)
        }
        .frame(width: 40, height: 40)
    }

    // MARK: History section

    /// Last 5 logs, newest first, in a card. If there are more than 5 a
    /// "View all" button at the bottom opens HabitHistoryView.
    private var historySection: some View {
        let recent = recentLogs(limit: 5)
        let totalCount = (habit.logs ?? []).filter { $0.modelContext != nil }.count
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("HISTORY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                Spacer()
                Text("\(totalCount) total")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.xs)

            if recent.isEmpty {
                emptyHistoryCard
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, log in
                        historyRow(log)
                        if index < recent.count - 1 {
                            Divider().overlay(Color.bgTertiary).padding(.leading, 56)
                        }
                    }
                    if totalCount > recent.count {
                        Divider().overlay(Color.bgTertiary).padding(.leading, 56)
                        viewAllRow(totalCount: totalCount)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Color.bgSecondary)
                )
            }
        }
    }

    private func historyRow(_ log: HabitLog) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.accentSage.opacity(0.18))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(relativeDayLabel(log.loggedAt))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(fullDateTimeLabel(log.loggedAt))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
    }

    private func viewAllRow(totalCount: Int) -> some View {
        Button {
            showHistory = true
        } label: {
            HStack {
                Text("View all")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                Text("(\(totalCount))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyHistoryCard: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 14))
                .foregroundStyle(Color.accentSage)
            Text("No stones placed yet. The first one is the heaviest.")
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func recentLogs(limit: Int) -> [HabitLog] {
        (habit.logs ?? [])
            .filter { $0.modelContext != nil }
            .sorted { $0.loggedAt > $1.loggedAt }
            .prefix(limit)
            .map { $0 }
    }

    private func relativeDayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let day = cal.startOfDay(for: date)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        if cal.isDate(day, inSameDayAs: today) { return "Today" }
        if cal.isDate(day, inSameDayAs: yesterday) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: day, to: today).day ?? 0
        if days < 7 { return "\(days) days ago" }
        let weeks = days / 7
        return weeks == 1 ? "Last week" : "\(weeks) weeks ago"
    }

    private func fullDateTimeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · HH:mm"
        return f.string(from: date)
    }

    // MARK: Derived

    private var friendlyCategoryName: String {
        switch habit.category {
        case .meds: return "Medication"
        case .water: return "Hydration"
        case .movement: return "Movement"
        case .focus: return "Focus"
        case .sleep: return "Sleep"
        case .transition: return "Transition"
        case .hyperfocusCheckIn: return "Check-in"
        case .custom: return "Habit"
        }
    }

    /// Grammar helper: "0 days", "1 day", "5 days".
    private func daysCountText(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private var reminderTimeText: String {
        guard let t = habit.notificationTimes.first else { return "Off" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: t)
    }

    private var daysText: String {
        switch habit.schedule {
        case .daily: return "Every day"
        case .weekdays: return "Mon — Fri"
        case .weekends: return "Sat, Sun"
        case .custom:
            let names = habit.customDays.sorted().map(HabitEditDraft.shortDayLabel)
            return names.joined(separator: " · ")
        }
    }

    // MARK: Month stats
    // "Placed N of M this month" — scheduled = number of days in this month
    // up to today on which the habit is supposed to occur.

    private struct MonthStats {
        let placed: Int
        let scheduled: Int
        var fraction: Double {
            scheduled > 0 ? min(1, Double(placed) / Double(scheduled)) : 0
        }
    }

    private var monthStats: MonthStats {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        // Start of this month at 00:00.
        let comps = cal.dateComponents([.year, .month], from: today)
        let monthStart = cal.date(from: comps) ?? today

        // Effective window start: don't count days before the habit existed.
        // For a habit created mid-month, scheduled days are only those from
        // creation onward — otherwise a new habit shows a discouraging
        // "1 of 17" denominator on day one.
        let creationDay = cal.startOfDay(for: habit.createdAt)
        let effectiveStart = max(monthStart, creationDay)

        // Scheduled days = days from effectiveStart up to today (inclusive)
        // where this habit's schedule includes that weekday.
        let scheduledWeekdays = HabitEditDraft.weekdays(for: habit)
        var scheduled = 0
        var cursor = effectiveStart
        while cursor <= today {
            let weekday = cal.component(.weekday, from: cursor)
            if scheduledWeekdays.contains(weekday) {
                scheduled += 1
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        // Placed = unique days in this month (from effectiveStart) with at
        // least one log.
        let placed = (habit.logs ?? [])
            .filter { log in
                guard log.modelContext != nil else { return false }
                let day = cal.startOfDay(for: log.loggedAt)
                return day >= effectiveStart && day <= today
            }
            .reduce(into: Set<Date>()) { acc, log in
                acc.insert(cal.startOfDay(for: log.loggedAt))
            }
            .count

        return MonthStats(placed: placed, scheduled: scheduled)
    }

    // MARK: Delete

    private func performDelete() {
        let habitRef = habit
        let ctx = context
        // Dismiss the cover first to avoid SwiftUI reading the habit while
        // SwiftData is detaching it.
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            let svc = HabitService(context: ctx)
            do {
                try svc.delete(habitRef)
            } catch {
                print("❌ Delete failed: \(error)")
            }
        }
    }
}
