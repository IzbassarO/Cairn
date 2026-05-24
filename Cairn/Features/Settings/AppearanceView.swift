import SwiftUI

// MARK: - AppearanceView
//
// One screen for everything visual: Theme and Text size. Replaces the three
// separate Settings rows (App icon / Theme / Text size). Both settings already
// cascade app-wide from RootView via AppSettings, so this screen is purely the
// picker UI; changing a value updates the whole app immediately.

struct AppearanceView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    private func close() { if let onClose { onClose() } else { dismiss() } }

    var body: some View {
        VStack(spacing: 0) {
            InfoScreenHeader(title: "Appearance", onClose: close)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    themeSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: Theme

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("THEME")
            HStack(spacing: Spacing.sm) {
                ForEach(ThemePreference.allCases) { theme in
                    themeCard(theme)
                }
            }
        }
    }

    private func themeCard(_ theme: ThemePreference) -> some View {
        let selected = settings.theme == theme
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                settings.theme = theme
            }
        } label: {
            VStack(spacing: Spacing.sm) {
                themePreview(theme)
                    .frame(height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .strokeBorder(selected ? Color.accentSage : Color.bgTertiary,
                                          lineWidth: selected ? 2 : 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.accentSage)
                                .background(Circle().fill(Color.bgSecondary).padding(2))
                                .padding(6)
                        }
                    }
                Text(theme.label.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(selected ? Color.accentSage : Color.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    /// A tiny faux-"Today" card previewing each theme's background + text.
    @ViewBuilder
    private func themePreview(_ theme: ThemePreference) -> some View {
        switch theme {
        case .light:
            previewContent(bg: Color(white: 0.96), line: Color(white: 0.75), title: Color(white: 0.2))
        case .dark:
            previewContent(bg: Color(white: 0.12), line: Color(white: 0.35), title: Color(white: 0.9))
        case .system:
            // Split diagonal: light top-left, dark bottom-right.
            ZStack {
                previewContent(bg: Color(white: 0.96), line: Color(white: 0.75), title: Color(white: 0.2))
                previewContent(bg: Color(white: 0.12), line: Color(white: 0.35), title: Color(white: 0.9))
                    .clipShape(DiagonalHalf())
            }
        }
    }

    private func previewContent(bg: Color, line: Color, title: Color) -> some View {
        ZStack(alignment: .topLeading) {
            bg
            VStack(alignment: .leading, spacing: 5) {
                Text("Today")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(title)
                Capsule().fill(Color.accentSage.opacity(0.8)).frame(width: 52, height: 4)
                Capsule().fill(line).frame(width: 40, height: 4)
                Capsule().fill(line).frame(width: 46, height: 4)
            }
            .padding(10)
        }
    }
    
    // MARK: Helpers
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Color.accentSage)
    }
}

// MARK: - Diagonal clip for the System theme preview

private struct DiagonalHalf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
