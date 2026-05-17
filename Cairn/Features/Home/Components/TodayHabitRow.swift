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
    /// Called when the user taps the row's body (anywhere outside the circle).
    /// Optional — old call sites without info navigation continue to work.
    var onRowTap: (() -> Void)? = nil

    /// "Just added" window: 5 minutes from habit creation. After that it's a
    /// regular unplaced row.
    private static let justAddedWindow: TimeInterval = 5 * 60

    private var isPlaced: Bool { habit.isFullyPlacedToday }
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
        // Row-level tap opens info. The inner Button (circle) wins for taps
        // that hit it — SwiftUI Button beats simultaneous gestures.
        .contentShape(Rectangle())
        .onTapGesture {
            onRowTap?()
        }
    }

    // MARK: Placed

    private var placedRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Sage check disc. When fully placed it's not a button anymore —
            // just a visual confirmation. This is the "1 tap is the whole day"
            // behavior: tapping it again does nothing.
            ZStack {
                Circle().fill(Color.accentSage)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
            .accessibilityLabel(placedAccessibilityLabel)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .strikethrough(true, color: Color.textSecondary.opacity(0.6))

                placedSubtitle
            }

            Spacer(minLength: Spacing.sm)

            trailingNumber
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private var placedAccessibilityLabel: String {
        habit.targetPerDay > 1
            ? "\(habit.name), completed \(habit.placedTodayCount) of \(habit.targetPerDay) today"
            : "\(habit.name), logged today"
    }

    /// What to show on the right edge of a placed row.
    ///  - target == 1: lifetime count (carry-over from N3 mock)
    ///  - target  > 1: today's progress "N/M"
    @ViewBuilder
    private var trailingNumber: some View {
        if habit.targetPerDay > 1 {
            Text("\(habit.placedTodayCount)/\(habit.targetPerDay)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        } else {
            Text("\(habit.lifetimeStones)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        }
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

                if habit.targetPerDay > 1 {
                    progressBadge
                }
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

    /// Small "N/M" pill shown on unplaced rows when targetPerDay > 1, so the
    /// user sees how many taps remain before the habit is fully placed today.
    private var progressBadge: some View {
        Text("\(habit.placedTodayCount)/\(habit.targetPerDay)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.accentSage)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.bgPrimary))
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
