import SwiftUI

/// One row in the Settings list. Visual model from mockup I but with
/// heavier label weight for stronger visual hierarchy.
///
/// Three variants:
///  - `.navigation(value:)`: chevron with optional grey value text
///  - `.toggle(isOn:)`: native iOS toggle, sage-tinted
///  - `.plain`: no trailing element
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
    /// When destructive, label renders in coral. Used for "Delete all data" etc.
    var isDestructive: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Spacing.md) {
                iconTile
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDestructive ? Color.accentCoral : Color.textPrimary)
                Spacer(minLength: 0)
                trailingContent
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isToggleVariant || action == nil && !isToggleVariant)
        .allowsHitTesting(action != nil || isToggleVariant)
    }

    private var isToggleVariant: Bool {
        if case .toggle = trailing { return true }
        return false
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill((isDestructive ? Color.accentCoral : iconTint).opacity(0.18))
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isDestructive ? Color.accentCoral : iconTint)
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
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

/// Eyebrow text above each section. Darker and heavier than before — sits
/// closer to a real heading than a quiet label.
struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.accentSage)
            .padding(.leading, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 6)
    }
}
