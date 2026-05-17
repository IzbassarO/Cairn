import SwiftUI
import SwiftData

/// Full-screen list of every log a habit has accumulated, grouped by day in
/// reverse-chronological order (newest first). Reached via the "View all"
/// button in `HabitInfoView`'s History section.
struct HabitHistoryView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss

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
                        ForEach(grouped, id: \.day) { day in
                            daySection(day)
                        }
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
                    Text("Info")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .accessibilityLabel("Back to habit info")

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HISTORY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
            Text(habit.name)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
            Text(totalLine)
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var totalLine: String {
        let total = grouped.reduce(0) { $0 + $1.logs.count }
        let days = grouped.count
        switch (total, days) {
        case (0, _): return "No stones yet."
        case (1, _): return "1 stone placed."
        case (_, 1): return "\(total) stones · 1 day."
        default: return "\(total) stones · \(days) days."
        }
    }

    // MARK: Day section

    private func daySection(_ day: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayHeader(day.day))
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(relativeDayLabel(day.day))
                    .font(.system(size: 12))
                    .italic()
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(day.logs.enumerated()), id: \.element.id) { index, log in
                    logRow(log)
                    if index < day.logs.count - 1 {
                        Divider().overlay(Color.bgTertiary).padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private func logRow(_ log: HabitLog) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.accentSage.opacity(0.18))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(timeString(log.loggedAt))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentSage.opacity(0.6))
            Text("No stones placed yet.")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
            Text("The first stone is the heaviest.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: Grouping

    private struct DayGroup {
        let day: Date          // startOfDay
        let logs: [HabitLog]   // sorted newest-first within the day
    }

    private var grouped: [DayGroup] {
        let cal = self.cal
        let validLogs = (habit.logs ?? []).filter { $0.modelContext != nil }
        let buckets = Dictionary(grouping: validLogs) { cal.startOfDay(for: $0.loggedAt) }
        return buckets
            .map { day, logs in
                DayGroup(day: day, logs: logs.sorted { $0.loggedAt > $1.loggedAt })
            }
            .sorted { $0.day > $1.day }
    }

    // MARK: Date formatting

    private func dayHeader(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private func relativeDayLabel(_ date: Date) -> String {
        let today = cal.startOfDay(for: .now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        if cal.isDate(date, inSameDayAs: today) { return "Today" }
        if cal.isDate(date, inSameDayAs: yesterday) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: today).day ?? 0
        if days < 7 { return "\(days) days ago" }
        let weeks = days / 7
        return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
