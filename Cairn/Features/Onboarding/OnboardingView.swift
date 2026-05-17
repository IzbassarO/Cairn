import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @AppStorage("userDisplayName") private var displayName: String = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = OnboardingPage.all

    private var currentPageData: OnboardingPage { pages[currentPage] }

    private var isNameStep: Bool {
        if case .nameField = currentPageData.hero { return true }
        return false
    }

    private var nameIsValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var ctaEnabled: Bool {
        isNameStep ? nameIsValid : true
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                pager
                indicator
                cta
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            // Skip is hidden on the name step — we want the name.
            if currentPage < pages.count - 1 && !isNameStep {
                Button {
                    advance(to: pages.count - 1)
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .padding(Spacing.md)
                }
                .accessibilityLabel("Skip onboarding")
            }
        }
        .frame(height: 44)
    }

    private var pager: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                OnboardingPageView(
                    page: page,
                    reduceMotion: reduceMotion,
                    name: $displayName
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.accentSage : Color.bgTertiary)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            }
        }
        .padding(.bottom, Spacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")
    }

    private var cta: some View {
        Button {
            handleCTA()
        } label: {
            Text(currentPageData.ctaTitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(Color.accentSage.opacity(ctaEnabled ? 1.0 : 0.45))
                )
                .shadow(
                    color: Color.accentSage.opacity(ctaEnabled ? 0.25 : 0),
                    radius: 10, y: 4
                )
        }
        .disabled(!ctaEnabled)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xl)
    }

    private func handleCTA() {
        if currentPage < pages.count - 1 {
            // Trim the name on the way out of the name step.
            if isNameStep {
                displayName = displayName.trimmingCharacters(in: .whitespaces)
            }
            advance(to: currentPage + 1)
        } else {
            // Final step: leave onboarding. TodayWelcomeView takes over and
            // offers gentle starters + "Write a custom habit".
            onComplete()
        }
    }

    private func advance(to page: Int) {
        if reduceMotion {
            currentPage = page
        } else {
            withAnimation(.easeInOut(duration: 0.35)) { currentPage = page }
        }
    }
}
