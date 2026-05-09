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
        sortOrder: Int = 0
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
    }

    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var schedule: HabitSchedule {
        get { HabitSchedule(rawValue: scheduleRaw) ?? .daily }
        set { scheduleRaw = newValue.rawValue }
    }
}
