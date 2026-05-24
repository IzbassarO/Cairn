import SwiftUI

struct SettingsProfileCard: View {
    let displayName: String
    let totalStones: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                ProfileAvatar(name: displayName, size: 60)
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

    // MARK: Text
    private var displayedName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    private var subtitle: String {
        switch totalStones {
        case 0: return "Cairn Free"
        case 1: return "Cairn Free · 1 stone placed"
        default: return "Cairn Free · \(totalStones) stones placed"
        }
    }
}
