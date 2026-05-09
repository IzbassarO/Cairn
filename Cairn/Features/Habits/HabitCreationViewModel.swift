import Foundation
import Observation

@MainActor
@Observable
final class HabitCreationViewModel {
    var selectedTemplate: HabitTemplate?
    var customName: String = ""
    var enableReminder: Bool = true
    var reminderTime: Date = Date()
    var errorMessage: String?

    var canSubmit: Bool {
        !customName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func selectTemplate(_ t: HabitTemplate) {
        selectedTemplate = t
        customName = t.name
        if let h = t.suggestedHour, let m = t.suggestedMinute {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            comps.hour = h
            comps.minute = m
            reminderTime = Calendar.current.date(from: comps) ?? Date()
            enableReminder = true
        } else {
            enableReminder = false
        }
    }

    func clearTemplate() {
        selectedTemplate = nil
    }

    func buildHabit(sortOrder: Int) -> Habit? {
        guard let t = selectedTemplate else { return nil }
        let trimmed = customName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let times: [Date] = enableReminder ? [reminderTime] : []
        return Habit(
            name: trimmed,
            iconName: t.iconName,
            colorTokenName: t.colorTokenName,
            category: t.category,
            schedule: .daily,
            notificationTimes: times,
            sortOrder: sortOrder
        )
    }
}
