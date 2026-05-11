import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
