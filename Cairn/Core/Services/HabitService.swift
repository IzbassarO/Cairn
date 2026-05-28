import Foundation
import SwiftData

@MainActor
struct HabitService {
    let context: ModelContext

    func add(_ habit: Habit) throws {
        context.insert(habit)
        try context.save()
    }

    /// True when an active habit with the same (trimmed, case-insensitive)
    /// name already shares at least one reminder time with the proposed one
    /// (or both have no reminder times). Lets the create flows block silly
    /// duplicates ("Drink water" at 09:00 added twice would just fire the
    /// same notification twice and double-count in stats).
    ///
    /// Allowed: same name + *different* times, since a multi-target habit can
    /// already model that via `notificationTimes` / `targetPerDay`.
    func duplicateExists(name: String, reminderTimes: [Date]) throws -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return false }

        let cal = Calendar.current
        let proposed = Set(reminderTimes.map { minuteSlot(for: $0, calendar: cal) })

        let actives = try context.fetch(FetchDescriptor<Habit>()).filter { !$0.isArchived }
        for habit in actives {
            let habitName = habit.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard habitName == trimmed else { continue }

            let existing = Set(habit.notificationTimes.map { minuteSlot(for: $0, calendar: cal) })
            // Both name-matches with no reminders → semantically identical.
            if proposed.isEmpty, existing.isEmpty { return true }
            // Otherwise any shared minute-of-day slot makes it a duplicate.
            if !proposed.isEmpty, !proposed.intersection(existing).isEmpty { return true }
        }
        return false
    }

    /// Minute-of-day key (0…1439) so notification time comparisons ignore the
    /// underlying date and only consider hour:minute.
    private func minuteSlot(for date: Date, calendar: Calendar) -> Int {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    enum LogResult {
        case logged
        case alreadyAtCap
    }

    @discardableResult
    func log(_ habit: Habit, source: LogSource = .app, note: String? = nil) throws -> LogResult {
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

    /// Removes the single most recent stone placed today. For a once-a-day
    /// habit this un-places it; for a multi-target habit it decrements the
    /// count. Used to undo an accidental tap. No-op if nothing placed today.
    @discardableResult
    func removeLastStoneToday(_ habit: Habit) throws -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let latest = (habit.logs ?? [])
            .filter { cal.startOfDay(for: $0.loggedAt) == today }
            .max { $0.loggedAt < $1.loggedAt }
        guard let latest else { return false }
        context.delete(latest)
        try context.save()
        return true
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
