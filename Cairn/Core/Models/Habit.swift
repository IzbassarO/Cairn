import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "circle.fill"
    var colorTokenName: String = "accent.sage"
    var categoryRaw: Int = 99
    var scheduleRaw: Int = 0
    var notificationTimes: [Date] = []
    var isArchived: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date.distantPast
    var customDaysRaw: String = ""

    /// How many times per day this habit can be logged. Defaults to 1.
    /// Enforced by `HabitService.log` — taps beyond the cap are no-ops.
    /// When > 1, the Today row shows "N/target" instead of the lifetime count.
    var targetPerDay: Int = 1

    /// Optional implementation-intention text in the "After I ____, I will ____" form.
    /// Editable in F7 (custom habit) and the future edit screen. Empty by default,
    /// in which case it's never shown.
    var cueNote: String = ""

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]? = []

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "circle.fill",
        colorTokenName: String = "accent.sage",
        category: HabitCategory = .custom,
        schedule: HabitSchedule = .daily,
        notificationTimes: [Date] = [],
        sortOrder: Int = 0,
        targetPerDay: Int = 1,
        cueNote: String = ""
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorTokenName = colorTokenName
        self.categoryRaw = category.rawValue
        self.scheduleRaw = schedule.rawValue
        self.notificationTimes = notificationTimes
        self.isArchived = false
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.targetPerDay = targetPerDay
        self.cueNote = cueNote
    }

    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var schedule: HabitSchedule {
        get { HabitSchedule(rawValue: scheduleRaw) ?? .daily }
        set { scheduleRaw = newValue.rawValue }
    }

    var customDays: Set<Int> {
        get { Set(customDaysRaw.split(separator: ",").compactMap { Int($0) }) }
        set { customDaysRaw = newValue.sorted().map(String.init).joined(separator: ",") }
    }
}
