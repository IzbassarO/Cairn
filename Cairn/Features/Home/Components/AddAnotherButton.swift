import SwiftUI

/// "+ Add another" button next to the section header.
/// Two visual styles depending on how many habits the user has:
///  - `.ghost` (F6, exactly 1 habit): text link in sage with a + glyph
///  - `.pill` (N3, 2+ habits): sage capsule, white text
struct AddAnotherButton: View {
    enum Style {
        case ghost
        case pill
    }

    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("Add another")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add another habit")
    }

    private var foreground: Color {
        switch style {
        case .ghost: return Color.accentSage
        case .pill: return .white
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .ghost: return 0
        case .pill: return 16
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .ghost: return 4
        case .pill: return 10
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .ghost:
            EmptyView()
        case .pill:
            Capsule().fill(Color.accentSage)
        }
    }
}
