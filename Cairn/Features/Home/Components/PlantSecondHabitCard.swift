import SwiftUI

/// Dashed-bordered card with a seedling icon, shown on Today when the user
/// has exactly 1 habit. Invites them to plant a second — but gently, without
/// pressure. Tap → opens the add-another flow.
struct PlantSecondHabitCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle().fill(Color.accentSage.opacity(0.20))
                    Image(systemName: "leaf")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentSage)
                }
                .frame(width: 36, height: 36)

                Text("When you're ready, plant a second habit.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        Color.accentSage.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Color.accentSage.opacity(0.06))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
