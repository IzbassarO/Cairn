import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showHabitCreation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = OnboardingPage.all

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
        .sheet(isPresented: $showHabitCreation, onDismiss: onComplete) {
            HabitCreationSheet()
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            if currentPage < pages.count - 1 {
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
                OnboardingPageView(page: page, reduceMotion: reduceMotion)
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
            if currentPage < pages.count - 1 {
                advance(to: currentPage + 1)
            } else {
                showHabitCreation = true
            }
        } label: {
            Text(pages[currentPage].ctaTitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.accentSage))
                .shadow(color: Color.accentSage.opacity(0.25), radius: 10, y: 4)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xl)
    }

    private func advance(to page: Int) {
        if reduceMotion {
            currentPage = page
        } else {
            withAnimation(.easeInOut(duration: 0.35)) { currentPage = page }
        }
    }
}
