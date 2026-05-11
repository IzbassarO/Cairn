import Foundation
import Observation

@MainActor
@Observable
final class HabitCreationViewModel {
    var selectedTemplate: HabitTemplate?
    var customName: String = ""
    var times: [Date] = []
    var schedule: HabitSchedule = .daily
    var customDays: Set<Int> = []
    var errorMessage: String?

    var canSubmit: Bool {
        let nameOk = !customName.trimmingCharacters(in: .whitespaces).isEmpty
        let scheduleOk = times.isEmpty || schedule != .custom || !customDays.isEmpty
        return nameOk && scheduleOk
    }

    func selectTemplate(_ t: HabitTemplate) {
        selectedTemplate = t
        customName = t.name
        schedule = .daily
        customDays = []
        if let h = t.suggestedHour, let m = t.suggestedMinute {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            comps.hour = h; comps.minute = m
            if let date = Calendar.current.date(from: comps) {
                times = [date]
            }
        } else {
            times = []
        }
    }

    func clearTemplate() { selectedTemplate = nil }

    func buildHabit(sortOrder: Int) -> Habit? {
        guard let t = selectedTemplate else { return nil }
        let trimmed = customName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let habit = Habit(
            name: trimmed,
            iconName: t.iconName,
            colorTokenName: t.colorTokenName,
            category: t.category,
            schedule: schedule,
            notificationTimes: times.sorted(),
            sortOrder: sortOrder
        )
        habit.customDays = schedule == .custom ? customDays : []
        return habit
    }
}
