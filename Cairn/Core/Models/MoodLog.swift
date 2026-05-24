import Foundation
import SwiftData

@Model
final class MoodLog {
    var id: UUID = UUID()
    var day: Date = Date.distantPast
    var moodRaw: Int = MoodValue.okay.rawValue
    var loggedAt: Date = Date.distantPast

    init(id: UUID = UUID(), day: Date, mood: MoodValue, loggedAt: Date = .now) {
        self.id = id
        self.day = day
        self.moodRaw = mood.rawValue
        self.loggedAt = loggedAt
    }

    var mood: MoodValue {
        get { MoodValue(rawValue: moodRaw) ?? .okay }
        set { moodRaw = newValue.rawValue }
    }
}

enum MoodValue: Int, CaseIterable {
    case foggy = 0
    case off = 1
    case okay = 2
    case good = 3
    case bright = 4

    var label: String {
        switch self {
        case .foggy: return "foggy"
        case .off: return "off"
        case .okay: return "okay"
        case .good: return "good"
        case .bright: return "bright"
        }
    }
}
