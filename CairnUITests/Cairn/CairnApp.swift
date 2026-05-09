import SwiftUI
import SwiftData

@main
struct CairnApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Habit.self,
            HabitLog.self,
            CoachMessage.self,
            UserProfile.self
        ])
    }
}

struct RootView: View {
    var body: some View {
        HomeView()
            .tint(Color.accentSage)
    }
}
