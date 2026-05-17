import SwiftUI

/// Dark sage card showing the user's next scheduled habit. Visual model
/// from mockup T:
///  - Dashed sage circle around an icon (left)
///  - Eyebrow `UP NEXT · IN 18 MIN` + habit name (white serif) + italic cue
///  - Sage pill `Start now` (right) — visual only in v1.0
///
/// Hidden by the caller when there's no next reminder (`nextHabit` nil).
struct UpNextCard: View {
    let habit: Habit
    /// Reminder time (the actual `Date` of the upcoming notification today).
    let reminderTime: Date

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            iconDisc

            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrowText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                Text(habit.name)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let cue = displayedCue {
                    Text(cue)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.sm)

            // Visual only — no action wired in v1.0.
            Text("Start now")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.accentSage))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.textPrimary)
        )
    }

    // MARK: Pieces

    private var iconDisc: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    Color.accentSage.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                )
            Image(systemName: habit.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .frame(width: 48, height: 48)
    }

    /// Prefer the habit's own cueNote. Fall back to the matching template's
    /// cue if the user didn't add one.
    private var displayedCue: String? {
        if !habit.cueNote.isEmpty {
            return habit.cueNote
        }
        return HabitTemplates.all.first {
            $0.name.lowercased() == habit.name.lowercased()
        }?.cue
    }

    private var eyebrowText: String {
        let minutes = Int(reminderTime.timeIntervalSinceNow / 60)
        switch minutes {
        case ..<0:
            // Past due — still show as up next (e.g. user opened the app late).
            return "UP NEXT · DUE NOW"
        case 0:
            return "UP NEXT · NOW"
        case 1:
            return "UP NEXT · IN 1 MIN"
        case 2..<60:
            return "UP NEXT · IN \(minutes) MIN"
        default:
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return "UP NEXT · AT \(f.string(from: reminderTime))"
        }
    }
}
