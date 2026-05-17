import SwiftUI

/// Horizontal card showing today's stone progress.
///
/// Two layouts:
///  - **Resting** (0 placed): single stone + "One small habit, ready when you are."
///  - **Stacking** (≥1 placed): stacked stones + "N placed, M to go." + progress bar
///
/// `placedToday` and `totalToday` are pre-computed by the parent — this view
/// just renders.
struct TodayCairnCard: View {
    let placedToday: Int
    let totalToday: Int

    private var isResting: Bool { placedToday == 0 }
    private var isComplete: Bool { placedToday >= totalToday && totalToday > 0 }
    private var remaining: Int { max(0, totalToday - placedToday) }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Hero on the left.
            TodayCairnHero(
                state: isResting ? .resting : .stacking(placed: placedToday),
                width: 96
            )

            // Text + progress on the right.
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY'S CAIRN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)

                copy

                if !isResting {
                    progressBar
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Copy

    @ViewBuilder
    private var copy: some View {
        if isResting {
            // "One small habit, ready when you are." — second line italic + sage
            VStack(alignment: .leading, spacing: 0) {
                Text(restingHeadline)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("ready when you are.")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
            .fixedSize(horizontal: false, vertical: true)
        } else if isComplete {
            // All done.
            HStack(spacing: 4) {
                Text("\(placedToday) placed.")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("Beautiful.")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
        } else {
            // "1 placed, 2 to go." — the "to go" part is italic + sage.
            HStack(spacing: 4) {
                Text("\(placedToday) placed,")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text(toGoText)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
        }
    }

    private var restingHeadline: String {
        // "One small habit," / "Two small habits," / etc — fall back to "habits".
        switch totalToday {
        case 1: return "One small habit,"
        case 2: return "Two small habits,"
        case 3: return "Three small habits,"
        default: return "\(totalToday) small habits,"
        }
    }

    private var toGoText: String {
        remaining == 1 ? "1 to go." : "\(remaining) to go."
    }

    // MARK: Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.accentSage.opacity(0.20))
                Capsule()
                    .fill(Color.accentSage)
                    .frame(width: geo.size.width * progressFraction)
                    .animation(.spring(response: 0.55, dampingFraction: 0.78),
                               value: progressFraction)
            }
        }
        .frame(height: 6)
    }

    private var progressFraction: CGFloat {
        guard totalToday > 0 else { return 0 }
        return min(1, CGFloat(placedToday) / CGFloat(totalToday))
    }
}
