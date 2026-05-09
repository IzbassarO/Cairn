import Foundation

enum HabitCategory: Int, Codable, CaseIterable {
    case meds = 0
    case sleep = 1
    case water = 2
    case movement = 3
    case focus = 4
    case transition = 5
    case hyperfocusCheckIn = 6
    case custom = 99

    var displayName: String {
        switch self {
        case .meds: return "Medication"
        case .sleep: return "Sleep"
        case .water: return "Water"
        case .movement: return "Movement"
        case .focus: return "Focus block"
        case .transition: return "Transition"
        case .hyperfocusCheckIn: return "Hyperfocus check-in"
        case .custom: return "Custom"
        }
    }

    var defaultIcon: String {
        switch self {
        case .meds: return "pills.fill"
        case .sleep: return "moon.zzz.fill"
        case .water: return "drop.fill"
        case .movement: return "figure.walk"
        case .focus: return "brain.head.profile"
        case .transition: return "arrow.triangle.swap"
        case .hyperfocusCheckIn: return "eye.fill"
        case .custom: return "circle.fill"
        }
    }
}

enum HabitSchedule: Int, Codable {
    case daily = 0
    case weekdays = 1
    case weekends = 2
    case custom = 99
}

enum LogSource: Int, Codable {
    case app = 0
    case widget = 1
    case siri = 2
    case watch = 3
    case shortcut = 4
}

enum MoodTag: Int, Codable {
    case easy = 0
    case ok = 1
    case struggle = 2
}

enum CoachMessageKind: Int, Codable {
    case dailyCheckIn = 0
    case weeklySummary = 1
    case reaction = 2
    case userComposed = 3
}

enum UserReaction: Int, Codable {
    case helpful = 0
    case noted = 1
    case notNow = 2
}

enum CoachTone: Int, Codable {
    case gentle = 0
    case structured = 1
    case bluntKind = 2
    case playful = 3
}

enum Appearance: Int, Codable {
    case system = 0
    case light = 1
    case dark = 2
    case highContrast = 3
}
