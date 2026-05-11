import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let reduceMotion: Bool

    @State private var heroScale: CGFloat = 0.85
    @State private var heroOpacity: Double = 0.0

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            hero
                .scaleEffect(heroScale)
                .opacity(heroOpacity)
                .onAppear { animateIn() }

            VStack(spacing: Spacing.md) {
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
