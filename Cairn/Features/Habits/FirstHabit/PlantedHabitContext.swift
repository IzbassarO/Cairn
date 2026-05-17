import Foundation

/// Lightweight value type passed from the first-habit add flow up to whatever
/// view orchestrates post-save behavior (permission prompt, scheduling, F5).
///
/// Carries:
///  - the SwiftData `Habit` reference, so the orchestrator can schedule
///    notifications after the user grants permission
///  - everything F5 needs to render
///
/// We keep the SwiftData reference here (rather than passing it across a
/// `fullScreenCover` boundary) because the orchestrator hands it off to
/// `NotificationService` immediately, before showing F5. F5 itself reads only
/// the plain string fields below.
struct PlantedHabitContext: Identifiable, Hashable {
    let id = UUID()
    let habit: Habit
    let habitName: String
    let timeLabel: String
    let daysLabel: String
    let notificationsOn: Bool

    static func == (lhs: PlantedHabitContext, rhs: PlantedHabitContext) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
