import Foundation
import SwiftData

@MainActor
struct HabitService {
    let context: ModelContext

    func add(_ habit: Habit) throws {
        context.insert(habit)
        try context.save()
    }

    func log(_ habit: Habit, source: LogSource = .app, note: String? = nil) throws {
        let entry = HabitLog(habit: habit, source: source, mood: nil)
        if let note { entry.note = note }
        context.insert(entry)
        try context.save()
    }

    func unlogToday(_ habit: Habit) throws {
        let today = Calendar.current.startOfDay(for: .now)
        let logsToday = (habit.logs ?? []).filter {
            Calendar.current.startOfDay(for: $0.loggedAt) == today
        }
        for log in logsToday {
            context.delete(log)
        }
        try context.save()
    }

    func delete(_ habit: Habit) throws {
        context.delete(habit)
        try context.save()
    }

    func reorder(_ habits: [Habit]) throws {
        for (index, habit) in habits.enumerated() {
            habit.sortOrder = index
        }
        try context.save()
    }

    func archive(_ habit: Habit) throws {
        habit.isArchived = true
        try context.save()
    }
}
