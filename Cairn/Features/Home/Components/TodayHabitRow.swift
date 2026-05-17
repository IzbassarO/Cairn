import SwiftUI

/// A single habit row on the Today screen. Visual state depends on whether
/// the habit was logged today and whether it was just added.
///
/// Layouts (from F6 / N3 mocks):
///  - **placed**: sage check disc, strikethrough name, "Placed at HH:MM · N in a row",
///    lifetime stones count on the right.
///  - **justAdded**: sage-tinted background, dashed circle around icon, "JUST ADDED"
///    pill on the right. No "tap to place" hint — user already knows what just happened.
///  - **unplaced**: sage-tinted background, dashed circle around icon, hint pill
///    "TAP THE CIRCLE TO PLACE YOUR STONE >".
struct TodayHabitRow: View {
    let habit: Habit
    let onLog: () -> Void

    /// "Just added" window: 5 minutes from habit creation. After that it's a
    /// regular unplaced row.
    private static let justAddedWindow: TimeInterval = 5 * 60

    private var isPlaced: Bool { habit.loggedToday }
    private var isJustAdded: Bool {
        !isPlaced && Date.now.timeIntervalSince(habit.createdAt) < Self.justAddedWindow
    }

    var body: some View {
        Group {
            if isPlaced {
                placedRow
            } else if isJustAdded {
                justAddedRow
            } else {
                unplacedRow
            }
        }
    }

    // MARK: Placed

    private var placedRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Sage check disc replaces the tap target. Tap re-logs (idempotent
            // — HabitService dedupes by day).
            Button(action: onLog) {
                ZStack {
                    Circle().fill(Color.accentSage)
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Logged today")

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .strikethrough(true, color: Color.textSecondary.opacity(0.6))

                placedSubtitle
            }

            Spacer(minLength: Spacing.sm)

            Text("\(habit.lifetimeStones)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private var placedSubtitle: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.textTertiary)
            Text(placedSubtitleText)
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var placedSubtitleText: String {
        let timeStr = todayLogTimeString
        let runDays = habit.currentRun
        if runDays >= 2 {
            return "Placed at \(timeStr) · \(runDays) in a row"
        }
        return "Placed at \(timeStr)"
    }

    private var todayLogTimeString: String {
        guard let log = habit.todayLog else { return "now" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: log.loggedAt)
    }

    // MARK: Just-added

    private var justAddedRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            dashedCircleButton

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                reminderSubtitle
            }

            Spacer(minLength: Spacing.sm)

            Text("JUST ADDED")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.accentSage))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
        )
    }

    // MARK: Unplaced (the F6 hint row)

    private var unplacedRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.md) {
                dashedCircleButton
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    reminderSubtitle
                }
                Spacer(minLength: 0)
            }

            // Hint pill — visible whenever the habit is unplaced today. Per spec
            // this is a permanent hint, not a one-shot tutorial.
            hintPill
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
        )
    }

    private var hintPill: some View {
        HStack(spacing: 6) {
            Text("TAP THE CIRCLE TO PLACE YOUR STONE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Color.accentSage)
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.accentSage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.bgPrimary))
    }

    // MARK: Shared bits

    /// Dashed sage circle around the habit icon. This is the tap target for
    /// "place a stone" on unplaced and just-added rows.
    private var dashedCircleButton: some View {
        Button(action: onLog) {
            ZStack {
                Circle()
                    .strokeBorder(
                        Color.accentSage,
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                    )
                Image(systemName: habit.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(habit.name)")
        .sensoryFeedback(.success, trigger: isPlaced)
    }

    /// Subtitle showing reminder time + cue (e.g. "08:30 · with breakfast").
    /// We don't store the cue per-habit yet, so for now we use the template
    /// `cue` if we can match the habit name. Otherwise just the time.
    @ViewBuilder
    private var reminderSubtitle: some View {
        if let first = habit.notificationTimes.first {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
                Text(timeString(first))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                if let cue = inferredCue {
                    Text("·")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                    Text(cue)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                }
            }
        } else if let cue = inferredCue {
            Text(cue)
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    /// Best-effort cue lookup: match habit name against the templates list.
    /// Returns nil for custom habits.
    private var inferredCue: String? {
        HabitTemplates.all
            .first { $0.name.lowercased() == habit.name.lowercased() }?
            .cue
    }
}
