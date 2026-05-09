import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String?
    var coachToneRaw: Int = 0
    var quietHoursStartMinutes: Int?
    var quietHoursEndMinutes: Int?
    var appearanceRaw: Int = 0
    var hasSeenOnboarding: Bool = false
    var trialStartedAt: Date?
    var dailyAITokensUsed: Int = 0
    var dailyAITokensResetAt: Date = Date.distantPast

    init(
        id: UUID = UUID(),
        coachTone: CoachTone = .gentle,
        appearance: Appearance = .system
    ) {
        self.id = id
        self.coachToneRaw = coachTone.rawValue
        self.appearanceRaw = appearance.rawValue
        self.hasSeenOnboarding = false
        self.dailyAITokensUsed = 0
        self.dailyAITokensResetAt = Calendar.current.startOfDay(for: .now)
    }

    var coachTone: CoachTone {
        get { CoachTone(rawValue: coachToneRaw) ?? .gentle }
        set { coachToneRaw = newValue.rawValue }
    }

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
