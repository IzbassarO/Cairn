import SwiftUI

/// Picker for notification tone. The user picks the **voice** of their
/// reminders — same time, same habit, different copy.
///
/// Three styles:
///  - **Gentle nudge**: soft, opt-in tone ("When you're ready — your water is waiting.")
///  - **Standard**: neutral reminder ("Time for: Drink water")
///  - **Bold**: more urgent, useful for habits the user finds hard to start
///    ("Drink water now. You'll thank yourself later.")
///
/// Saved as raw String in @AppStorage. NotificationService reads this when
/// scheduling and picks a body line from the matching corpus.
enum ReminderStyle: String, CaseIterable, Identifiable {
    case gentle = "gentle"
    case standard = "standard"
    case bold = "bold"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: return "Gentle nudge"
        case .standard: return "Standard"
        case .bold: return "Bold"
        }
    }

    var sampleText: String {
        switch self {
        case .gentle: return "When you're ready — your water is waiting."
        case .standard: return "Time for: Drink water"
        case .bold: return "Drink water now. Future-you will thank you."
        }
    }

    var description: String {
        switch self {
        case .gentle: return "Soft and opt-in. Best for low-energy mornings."
        case .standard: return "Direct and unfussy. Default behavior."
        case .bold: return "More urgent. Useful for habits that resist starting."
        }
    }

    var iconName: String {
        switch self {
        case .gentle: return "leaf"
        case .standard: return "bell"
        case .bold: return "bolt"
        }
    }
}

struct ReminderStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("reminderStyle") private var rawStyle: String = ReminderStyle.gentle.rawValue

    private var current: ReminderStyle {
        ReminderStyle(rawValue: rawStyle) ?? .gentle
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock
                    VStack(spacing: Spacing.sm) {
                        ForEach(ReminderStyle.allCases) { style in
                            styleCard(style)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Settings")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            Spacer()
            Text("Reminder style")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Pick a")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("voice.")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
            Text("Same time, same habit — different tone.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: Cards

    private func styleCard(_ style: ReminderStyle) -> some View {
        let isSelected = current == style
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                rawStyle = style.rawValue
            }
        } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                iconTile(systemName: style.iconName)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(style.label)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        selectionIndicator(isSelected: isSelected)
                    }
                    Text(style.sampleText)
                        .font(.system(size: 14, design: .serif))
                        .italic()
                        .foregroundStyle(Color.accentSage)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(style.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(isSelected ? Color.accentSage.opacity(0.15) : Color.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentSage : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func iconTile(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.accentSage)
        }
        .frame(width: 34, height: 34)
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? Color.clear : Color.textTertiary.opacity(0.4),
                    lineWidth: 1.5
                )
            if isSelected {
                Circle().fill(Color.accentSage)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 22, height: 22)
    }
}
