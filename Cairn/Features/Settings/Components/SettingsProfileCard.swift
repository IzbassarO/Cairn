import SwiftUI

/// Top user card on Settings screen.
///
/// Avatar = circle with the first letter of the user's display name (sage
/// background). To the right: username (serif bold), "Cairn Free · N stones
/// placed" subtitle, chevron. Tap → opens ProfileView (added in next request).
struct SettingsProfileCard: View {
    let displayName: String
    let totalStones: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                avatar
                VStack(alignment: .leading, spacing: 2) {
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
        .buttonStyle(.plain)
    }

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

    private var avatar: some View {
        ZStack {
            Circle().fill(Color.accentSage)
            Text(firstLetter)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(.white)
        }
        .frame(width: 56, height: 56)
    }
}
