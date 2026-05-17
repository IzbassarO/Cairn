import SwiftUI

/// Subdued card with a leaf icon and a daily coach line. Text is pulled from
/// `CoachMessages.dailyMessage(activeHabitCount:)` — picked deterministically
/// from the date, so it stays stable through the day.
struct CoachCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.accentSage.opacity(0.20))
                Image(systemName: "leaf")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text("COACH")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                Text(message)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }
}
