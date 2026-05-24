import SwiftUI
import SwiftData

@main
struct CairnApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
        }
        .modelContainer(for: [
            Habit.self,
            HabitLog.self,
            CoachMessage.self,
            UserProfile.self,
            MoodLog.self
        ])
    }
}
