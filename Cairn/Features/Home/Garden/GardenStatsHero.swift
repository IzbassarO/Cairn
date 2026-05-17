import SwiftUI

/// Three stat cards above the calendar. Visual model from mockup G:
///  - Stones (sage-tinted, primary)
///  - Active days (neutral)
///  - Gentle days (neutral)
///
/// "Active" = days with at least one stone placed.
/// "Gentle" = days the user explicitly rested (no logs, but the day passed).
/// We don't currently distinguish "intentional rest" from "missed" — for v1.0
/// gentle = days within the month where no habit was placed AND at least one
/// habit was scheduled. It still reads better than "missed days".
struct GardenStatsHero: View {
    let stones: Int
    let activeDays: Int
    let gentleDays: Int

    var body: some View {
        HStack(spacing: 10) {
            statCard(value: "\(stones)", label: "stones", emphasized: true)
            statCard(value: "\(activeDays)", label: "active days", emphasized: false)
            statCard(value: "\(gentleDays)", label: "gentle days", emphasized: false)
        }
    }

    private func statCard(value: String, label: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(emphasized ? Color.accentSage.opacity(0.22) : Color.bgSecondary)
        )
    }
}
