import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorTokenName: String
    var category: HabitCategory
    var scheduleRaw: Int
    var notificationTimes: [Date]
    var isArchived: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

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
        self.category = category
        self.scheduleRaw = schedule.rawValue
        self.notificationTimes = notificationTimes
        self.isArchived = false
        self.sortOrder = sortOrder
        self.createdAt = .now
    }

    var schedule: HabitSchedule {
        get { HabitSchedule(rawValue: scheduleRaw) ?? .daily }
        set { scheduleRaw = newValue.rawValue }
    }
}
