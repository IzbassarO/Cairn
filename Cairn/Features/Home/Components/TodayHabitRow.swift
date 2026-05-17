import SwiftUI

/// One habit row on the Today list. Visual model from mockup T:
///  - **Placed**: solid sage circle with check, strikethrough name, "Placed at"
///  - **Just added**: dashed sage border around the whole row, JUST ADDED pill
///  - **Unplaced**: dashed sage border + reminder pill + sage plus button
///
/// Rows are dense — no card background — so a list of 6 reads naturally and
/// doesn't push the rest of Today off-screen.
struct TodayHabitRow: View {
    let habit: Habit
    let onLog: () -> Void
    var onRowTap: (() -> Void)? = nil

    /// 5-minute window after creation: shows "JUST ADDED" instead of the
    /// normal unplaced state.
    private static let justAddedWindow: TimeInterval = 5 * 60

    private var isPlaced: Bool { habit.isFullyPlacedToday }
    private var isJustAdded: Bool {
        !isPlaced && Date.now.timeIntervalSince(habit.createdAt) < Self.justAddedWindow
    }

    var body: some View {
        rowContent
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(rowBackground)
            .contentShape(Rectangle())
            .onTapGesture { onRowTap?() }
    }

    // MARK: Background variant per state

    @ViewBuilder
    private var rowBackground: some View {
        if isPlaced {
            // Subtle filled card for placed habits, signals "done & resting"
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bgSecondary.opacity(0.55))
        } else {
            // Dashed sage outline for unplaced + just-added
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    Color.accentSage.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                )
        }
    }

    // MARK: Content variant per state

    @ViewBuilder
    private var rowContent: some View {
        if isPlaced {
            placedRow
        } else if isJustAdded {
            justAddedRow
        } else {
            unplacedRow
        }
    }

    // MARK: Placed

    private var placedRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Button(action: onLog) {
                ZStack {
                    Circle().fill(Color.accentSage)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Logged today")

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .strikethrough(true, color: Color.textSecondary.opacity(0.5))
                Text(placedSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer(minLength: 0)

            trailingNumber
        }
    }

    private var placedSubtitle: String {
        guard let log = habit.todayLog else { return "Placed" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let timeStr = f.string(from: log.loggedAt)
        let runDays = habit.currentRun
        if runDays >= 2 {
            return "Placed at \(timeStr) · \(runDays) in a row"
        }
        return "Placed at \(timeStr)"
    }

    /// Lifetime count (target=1) or N/target (target>1).
    @ViewBuilder
    private var trailingNumber: some View {
        if habit.targetPerDay > 1 {
            Text("\(habit.placedTodayCount)/\(habit.targetPerDay)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        } else {
            Text("\(habit.lifetimeStones)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        }
    }

    // MARK: Just added

    private var justAddedRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            iconDisc
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                reminderLine
            }
            Spacer(minLength: 0)
            Text("JUST ADDED")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.accentSage))
        }
    }

    // MARK: Unplaced

    private var unplacedRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            iconDisc
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                reminderLine
            }
            Spacer(minLength: 0)
            if let timeStr = reminderTimeString {
                Text(timeStr)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.accentSage)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.accentSage.opacity(0.18)))
            }
            plusButton
        }
    }

    // MARK: Pieces

    private var iconDisc: some View {
        Button(action: onLog) {
            ZStack {
                Circle()
                    .fill(Color.accentSage.opacity(0.18))
                Image(systemName: habit.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 40, height: 40)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(habit.name)")
    }

    private var plusButton: some View {
        Button(action: onLog) {
            ZStack {
                Circle().fill(Color.accentSage)
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Place a stone for \(habit.name)")
    }

    @ViewBuilder
    private var reminderLine: some View {
        if let cue = displayedCue {
            Text(cue)
                .font(.system(size: 12))
                .italic()
                .foregroundStyle(Color.textTertiary)
                .lineLimit(1)
        }
    }

    private var reminderTimeString: String? {
        guard let first = habit.notificationTimes.first else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: first)
    }

    /// Habit's own cue note first; fall back to matching template's cue.
    private var displayedCue: String? {
        if !habit.cueNote.isEmpty {
            return habit.cueNote
        }
        return HabitTemplates.all.first {
            $0.name.lowercased() == habit.name.lowercased()
        }?.cue
    }
}
