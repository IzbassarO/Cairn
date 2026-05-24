import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
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
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }

            CoachView()
                .tabItem {
                    Label("Coach", systemImage: "leaf.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
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
