import SwiftUI

/// "How's your morning?" mood selector. Five rounded square cards in a row,
/// shaded from light-sage (foggy, left) to deep-sage (bright, right). Tapping
/// a card fires `onSelect`; the parent persists and animates the whole card
/// away.
///
/// The eyebrow word rotates with time of day (morning / afternoon / evening
/// / night) so the card stays meaningful all day.
struct MoodSelector: View {
    /// Currently-selected mood, if any. Drives the white-dot indicator.
    let selected: MoodValue?
    let onSelect: (MoodValue) -> Void

    /// The mood just tapped — held briefly so the choice visibly registers
    /// (highlight + scale + check) before the parent collapses the card.
    @State private var justPicked: MoodValue?

    private func pick(_ mood: MoodValue) {
        guard justPicked == nil else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            justPicked = mood
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onSelect(mood)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(eyebrowText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)

            HStack(spacing: 8) {
                ForEach(MoodValue.allCases, id: \.rawValue) { mood in
                    moodCard(mood)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Card

    private func moodCard(_ mood: MoodValue) -> some View {
        let isSelected = (justPicked ?? selected) == mood
        return Button {
            pick(mood)
        } label: {
            VStack(spacing: 6) {
                indicatorDot(isSelected: isSelected, mood: mood)
                Text(mood.label)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(isSelected ? .white : Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(backgroundColor(for: mood, isSelected: isSelected))
            )
            .scaleEffect(isSelected ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(justPicked != nil)
        .accessibilityLabel("\(mood.label) — feeling")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// White check when this card is selected; otherwise a faint hollow circle
    /// (lighter than the card so it shows through).
    private func indicatorDot(isSelected: Bool, mood: MoodValue) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.white : Color.white.opacity(0.35))
                .frame(width: 18, height: 18)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentSage)
            }
        }
    }

    /// Sage gradient: leftmost (foggy) is palest, rightmost (bright) is darkest.
    /// Selected cards become a saturated sage regardless of position.
    private func backgroundColor(for mood: MoodValue, isSelected: Bool) -> Color {
        if isSelected {
            return Color.accentSage
        }
        // 0 → 0.22, 1 → 0.32, 2 → 0.42, 3 → 0.52, 4 → 0.62 opacity
        let opacity = 0.22 + Double(mood.rawValue) * 0.10
        return Color.accentSage.opacity(opacity)
    }

    // MARK: Eyebrow

    private var eyebrowText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let period: String
        switch hour {
        case 5..<12: period = "MORNING"
        case 12..<17: period = "AFTERNOON"
        case 17..<22: period = "EVENING"
        default: period = "NIGHT"
        }
        return "HOW'S YOUR \(period)?"
    }
}
