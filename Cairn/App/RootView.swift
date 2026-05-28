import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var settings: AppSettings

    /// Explicit tab selection so changing theme/text size (which rebuilds the
    /// view tree) doesn't reset the user back to the first tab.
    @State private var selectedTab: Tab = .today

    private enum Tab: Hashable { case today, coach, settings }

    var body: some View {
        // SlideCoverHost provides the root-level overlay layer that
        // .slideCover renders into, so drill-in screens sit *above* the
        // tab bar without animating it in and out.
        SlideCoverHost {
            Group {
                if hasCompletedOnboarding {
                    mainTabs
                } else {
                    OnboardingView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasCompletedOnboarding = true
                        }
                    })
                    .transition(.opacity)
                }
            }
        }
        // Settings cascade across the whole app:
        .preferredColorScheme(resolvedColorScheme)
        .modifier(TextSizeModifier(size: settings.textSize.dynamicTypeSize))
    }

    /// Maps the theme preference onto SwiftUI's optional ColorScheme.
    private var resolvedColorScheme: ColorScheme? {
        switch settings.theme.colorScheme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }
                .tag(Tab.today)

            CoachView()
                .tabItem {
                    Label("Coach", systemImage: "leaf.fill")
                }
                .tag(Tab.coach)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color.accentSage)
    }
}

/// Applies a fixed Dynamic Type size only when the user picked a non-standard
/// option. Standard (nil) leaves the system setting untouched.
private struct TextSizeModifier: ViewModifier {
    let size: DynamicTypeSize?
    func body(content: Content) -> some View {
        if let size {
            content.dynamicTypeSize(size)
        } else {
            content
        }
    }
}
