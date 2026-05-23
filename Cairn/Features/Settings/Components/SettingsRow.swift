import SwiftUI

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
