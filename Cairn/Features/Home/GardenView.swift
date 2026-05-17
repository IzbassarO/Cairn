import SwiftUI

/// Placeholder for the Garden screen (full calendar view of all stones).
/// Part C of the redesign will replace this with the real implementation
/// from mockup G. For now it's a friendly "coming soon" so the View Garden
/// button on TodayCairnCard has somewhere to land.
struct GardenView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            content
            Spacer()
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Today")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            Spacer()
            Text("Garden")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            // Invisible spacer to keep title centered.
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    private var content: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "leaf")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.accentSage)
            Text("Garden")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text("Coming soon — a calendar of every stone you've placed.")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
    }
}
