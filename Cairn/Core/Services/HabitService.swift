import Foundation
import SwiftData

@MainActor
struct HabitService {
    let context: ModelContext

    func add(_ habit: Habit) throws {
        context.insert(habit)
        try context.save()
    }

    /// Result of a log attempt. The UI can ignore this and just call `log()`
    /// fire-and-forget — at-cap taps are silently dropped.
    enum LogResult {
        case logged
        case alreadyAtCap
    }

    @discardableResult
    func log(_ habit: Habit, source: LogSource = .app, note: String? = nil) throws -> LogResult {
        // Enforce per-day cap. Each habit defines its own `targetPerDay`
        // (defaults to 1). Beyond the cap, taps are a no-op.
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let countToday = (habit.logs ?? []).filter {
            cal.startOfDay(for: $0.loggedAt) == today
        }.count

        guard countToday < max(1, habit.targetPerDay) else {
            return .alreadyAtCap
        }

        let entry = HabitLog(habit: habit, source: source, mood: nil)
        if let note { entry.note = note }
        context.insert(entry)
        try context.save()
        return .logged
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
        let id = habit.id
        NotificationService.shared.cancel(habitId: id)
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
        NotificationService.shared.cancel(habitId: habit.id)
        try context.save()
    }
}
