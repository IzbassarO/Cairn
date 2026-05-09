import Foundation
import SwiftData

@Model
final class CoachMessage {
    var id: UUID = UUID()
    var createdAt: Date = Date.distantPast
    var kindRaw: Int = 0
    var body: String = ""
    var modelUsed: String = ""
    var reactionRaw: Int?
    var inputTokens: Int = 0
    var outputTokens: Int = 0

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: CoachMessageKind,
        body: String,
        modelUsed: String,
        inputTokens: Int = 0,
        outputTokens: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.body = body
        self.modelUsed = modelUsed
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }

    var kind: CoachMessageKind {
        get { CoachMessageKind(rawValue: kindRaw) ?? .dailyCheckIn }
        set { kindRaw = newValue.rawValue }
    }

    var reaction: UserReaction? {
        get { reactionRaw.flatMap(UserReaction.init(rawValue:)) }
        set { reactionRaw = newValue?.rawValue }
    }
}
