import SwiftUI

/// One row in the Settings list.
///
/// Three variants share the same visual shell but render differently:
///  - `.navigation(value:)`: chevron with optional grey value text. Whole row
///    is a Button that fires `action` on tap.
///  - `.toggle(isOn:)`: native iOS toggle on the right. The row is NOT a
///    Button — that previously made the toggle look disabled because the
///    wrapping Button's pressed state dimmed everything. Now the toggle owns
///    its own tap handling, the rest of the row is a plain HStack.
///  - `.plain`: no trailing element. Whole row is a Button.
///
/// Weight choices:
///  - Label: 16pt semibold (clear hierarchy without shouting)
///  - Trailing value: 14pt regular (supportive, not competing)
///  - Chevron: 13pt medium (visible but understated)
///
/// Destructive variant uses `Color.red` — system red, not coral. Coral works
/// for app accents but reads too "soft" for a destructive action.
struct SettingsRow: View {
    enum Trailing {
        case navigation(value: String?)
        case toggle(isOn: Binding<Bool>)
        case plain
    }

    let icon: String
    let label: String
    var trailing: Trailing = .navigation(value: nil)
    var iconTint: Color = .accentSage
    /// When destructive, label and icon render in system red.
    var isDestructive: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        // Toggle rows can't be wrapped in a Button — Button's pressed state
        // dims the toggle. So we branch on the variant.
        switch trailing {
        case .toggle:
            rowContent
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
        case .navigation, .plain:
            Button { action?() } label: {
                rowContent
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(action == nil)
        }
    }

    private var rowContent: some View {
        HStack(spacing: Spacing.md) {
            iconTile
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isDestructive ? Color.red : Color.textPrimary)
            Spacer(minLength: 0)
            trailingContent
        }
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill((isDestructive ? Color.red : iconTint).opacity(0.15))
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isDestructive ? Color.red : iconTint)
        }
        .frame(width: 34, height: 34)
    }

    @ViewBuilder
    private var trailingContent: some View {
        switch trailing {
        case .navigation(let value):
            HStack(spacing: 6) {
                if let value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary.opacity(0.7))
            }
        case .toggle(let isOn):
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.accentSage)
        case .plain:
            EmptyView()
        }
    }
}

/// Section eyebrow. Bold textPrimary 14pt — reads as a real heading, not a
/// quiet eyebrow.
struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.textPrimary)
            .padding(.leading, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 6)
    }
}
