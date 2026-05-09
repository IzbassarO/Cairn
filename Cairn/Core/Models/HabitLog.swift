import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID = UUID()
    var habit: Habit?
    var loggedAt: Date = Date.distantPast
    var note: String?
    var sourceRaw: Int = 0
    var moodRaw: Int?

    init(
        id: UUID = UUID(),
        habit: Habit,
        loggedAt: Date = .now,
        note: String? = nil,
        source: LogSource = .app,
        mood: MoodTag? = nil
    ) {
        self.id = id
        self.habit = habit
        self.loggedAt = loggedAt
        self.note = note
        self.sourceRaw = source.rawValue
        self.moodRaw = mood?.rawValue
    }

    var source: LogSource {
        get { LogSource(rawValue: sourceRaw) ?? .app }
        set { sourceRaw = newValue.rawValue }
    }

    var mood: MoodTag? {
        get { moodRaw.flatMap(MoodTag.init(rawValue:)) }
        set { moodRaw = newValue?.rawValue }
    }
}
