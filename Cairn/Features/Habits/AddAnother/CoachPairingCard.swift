import SwiftUI

/// Sage-tinted card shown above the template list in N1 when CoachPairings
/// has a suggestion to make. Tapping the CTA opens N2 pre-filled with the
/// suggested template and a generated cue note.
struct CoachPairingCard: View {
    let pairing: CoachPairing
    let onAddPairing: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    Circle().fill(Color.bgPrimary)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentSage)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    Text("COACH PAIRING")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentSage)
                        .tracking(1.4)

                    Text(pairing.headline)
                        .font(.system(size: 19, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(pairing.rationale)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }

            Button(action: onAddPairing) {
                HStack {
                    Text("Add this pairing")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .fill(Color.accentSage)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
        )
    }
}
