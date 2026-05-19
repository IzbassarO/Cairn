import SwiftUI

/// Top user card on Settings screen. Visual model from mockup J header:
/// gradient sage avatar with italic serif initial, name + 'Cairn Free · N
/// stones placed' subtitle, chevron.
///
/// The avatar is the main upgrade vs v1: a soft top-down gradient + tiny
/// leaf accent in the bottom-right makes it feel like an object, not a flat
/// disk.
struct SettingsProfileCard: View {
    let displayName: String
    let totalStones: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                avatar
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayedName)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "leaf")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accentSage)
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary.opacity(0.7))
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: Avatar

    /// Gradient circle + inner highlight + small leaf accent. The letter is
    /// serif italic in cream-white so it feels handwritten rather than UI.
    private var avatar: some View {
        ZStack {
            // Base gradient — light sage top, deeper sage bottom.
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentSage.opacity(0.78),
                            Color.accentSage
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle top-left highlight to imply depth.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.32), .clear],
                        center: .init(x: 0.3, y: 0.25),
                        startRadius: 0,
                        endRadius: 30
                    )
                )

            // Initial — serif italic in cream.
            Text(firstLetter)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.bgPrimary)

            // Tiny leaf accent at bottom-right — same vocabulary as the rest
            // of the app (the 'Cairn Free' chip, the section icons).
            leafAccent
                .offset(x: 20, y: 20)
        }
        .frame(width: 60, height: 60)
        .shadow(color: Color.accentSage.opacity(0.32), radius: 8, y: 3)
    }

    private var leafAccent: some View {
        ZStack {
            Circle()
                .fill(Color.bgPrimary)
                .frame(width: 22, height: 22)
            Image(systemName: "leaf.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.accentSage)
        }
    }

    // MARK: Text

    private var displayedName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    private var firstLetter: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    /// "Cairn Free · 142 stones placed" or just "Cairn Free" when no stones yet.
    private var subtitle: String {
        switch totalStones {
        case 0: return "Cairn Free"
        case 1: return "Cairn Free · 1 stone placed"
        default: return "Cairn Free · \(totalStones) stones placed"
        }
    }
}
