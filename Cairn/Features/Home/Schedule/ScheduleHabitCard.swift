import SwiftUI

/// Read-only card on TodaySchedule timeline. Visual state shows what
/// happened with the reminder:
///  - `.completed`: habit was placed sometime today, regardless of when
///  - `.upcoming`: reminder time hasn't passed yet
///  - `.missed`: reminder time passed, habit still not placed
///
/// Cards are pure presentation — tapping does nothing. The schedule is for
/// "what does my day look like", actions live on the Today tab.
struct ScheduleHabitCard: View {
    enum State {
        case completed
        case upcoming
        case missed
    }

    let habit: Habit
    let reminderTime: Date
    let state: State

    var body: some View {
        HStack(spacing: Spacing.sm) {
            iconDisc

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(nameColor)
                    .strikethrough(state == .missed, color: Color.textTertiary.opacity(0.6))
                    .lineLimit(1)
                if let cue = displayedCue {
                    Text(cue)
                        .font(.system(size: 11))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            stateBadge
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(cardBackground)
    }

    // MARK: Pieces

    private var iconDisc: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
            Image(systemName: state == .completed ? "checkmark" : habit.iconName)
                .font(.system(size: 13, weight: state == .completed ? .bold : .medium))
                .foregroundStyle(iconForeground)
        }
        .frame(width: 28, height: 28)
    }

    @ViewBuilder
    private var stateBadge: some View {
        switch state {
        case .completed:
            // Tiny placed-at time. Read from todayLog if available.
            if let placedAt = habit.todayLog?.loggedAt {
                Text(timeString(placedAt))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.accentSage)
            }
        case .upcoming:
            Text(timeString(reminderTime))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.accentSage)
        case .missed:
            Text("missed")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .tracking(0.8)
                .textCase(.uppercase)
        }
    }

    // MARK: Colors per state

    @ViewBuilder
    private var cardBackground: some View {
        switch state {
        case .completed:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
        case .upcoming:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    Color.accentSage.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                )
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bgPrimary)
                )
        case .missed:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.bgTertiary.opacity(0.5))
        }
    }

    private var nameColor: Color {
        switch state {
        case .completed: return Color.textSecondary
        case .upcoming: return Color.textPrimary
        case .missed: return Color.textTertiary
        }
    }

    private var iconBackground: Color {
        switch state {
        case .completed: return Color.accentSage
        case .upcoming: return Color.accentSage.opacity(0.18)
        case .missed: return Color.bgTertiary
        }
    }

    private var iconForeground: Color {
        switch state {
        case .completed: return .white
        case .upcoming: return Color.accentSage
        case .missed: return Color.textTertiary
        }
    }

    // MARK: Cue

    private var displayedCue: String? {
        if !habit.cueNote.isEmpty {
            return habit.cueNote
        }
        return HabitTemplates.all.first {
            $0.name.lowercased() == habit.name.lowercased()
        }?.cue
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
