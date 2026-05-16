import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let reduceMotion: Bool
    /// Bound only when page.hero == .nameField. Parent owns the storage.
    @Binding var name: String

    @State private var heroScale: CGFloat = 0.85
    @State private var heroOpacity: Double = 0.0
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            hero
                .scaleEffect(heroScale)
                .opacity(heroOpacity)
                .onAppear { animateIn() }

            VStack(spacing: Spacing.sm) {
                if let eyebrow = page.eyebrow {
                    Text(eyebrow)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentSage)
                        .textCase(.uppercase)
                        .tracking(1.4)
                        .padding(.bottom, 2)
                }

                Text(page.headline)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subhead)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, Spacing.lg)

            if case .nameField = page.hero {
                nameInputField
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.sm)
            }

            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var hero: some View {
        switch page.hero {
        case .symbol(let name, let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 200, height: 200)
                Image(systemName: name)
                    .font(.system(size: 80, weight: .regular))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
        case .stackedStones:
            StackedStonesHero()
                .frame(width: 200, height: 200)
                .accessibilityHidden(true)
        case .singleStone:
            RestingStoneView(width: 180)
                .frame(width: 200, height: 200)
                .accessibilityHidden(true)
        case .nameField:
            // Smaller hero to leave room for the input.
            RestingStoneView(width: 140)
                .frame(width: 180, height: 140)
                .accessibilityHidden(true)
        }
    }

    private var nameInputField: some View {
        TextField("First name", text: $name)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(Color.textPrimary)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($nameFocused)
            .padding(.vertical, 14)
            .padding(.horizontal, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        nameFocused ? Color.accentSage : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .onAppear {
                // Slight delay so the page transition settles before keyboard pops up.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    nameFocused = true
                }
            }
    }

    private func animateIn() {
        heroScale = 0.85
        heroOpacity = 0.0
        if reduceMotion {
            heroScale = 1.0
            heroOpacity = 1.0
        } else {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                heroScale = 1.0
                heroOpacity = 1.0
            }
        }
    }
}

private struct StackedStonesHero: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentSage.opacity(0.12))

            VStack(spacing: 8) {
                stone(width: 76, opacity: 1.0)
                stone(width: 96, opacity: 0.88)
                stone(width: 120, opacity: 0.74)
            }
            .shadow(color: Color.accentSage.opacity(0.20), radius: 12, y: 4)
        }
    }

    private func stone(width: CGFloat, opacity: Double) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.accentSage.opacity(opacity),
                        Color.accentSage.opacity(opacity * 0.78)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
            )
            .frame(width: width, height: 26)
    }
}
