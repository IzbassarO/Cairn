import SwiftUI
import Observation

@Observable
final class HabitEditViewModel {
    var name: String
    var iconName: String
    var category: HabitCategory
    var times: [Date]
    var schedule: HabitSchedule
    var customDays: Set<Int>

    init(habit: Habit) {
        self.name = habit.name
        self.iconName = habit.iconName
        self.category = habit.category
        self.times = habit.notificationTimes
        self.schedule = habit.schedule
        self.customDays = habit.customDays
    }

    var canSave: Bool {
        let nameOk = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let scheduleOk = times.isEmpty || schedule != .custom || !customDays.isEmpty
        return nameOk && scheduleOk
    }

    func apply(to habit: Habit) {
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.iconName = iconName
        habit.category = category
        habit.notificationTimes = times.sorted()
        habit.schedule = schedule
        habit.customDays = schedule == .custom ? customDays : []
    }
}
