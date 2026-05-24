import Foundation

enum CoachPairings {

    static let pairingHabitCeiling = 3

    static func suggest(for activeHabits: [Habit]) -> CoachPairing? {
        guard activeHabits.count <= pairingHabitCeiling,
              !activeHabits.isEmpty
        else { return nil }

        let anchorHabit = activeHabits.sorted { $0.sortOrder < $1.sortOrder }.first!
        let anchorName = anchorHabit.name.lowercased()

        for pairing in mappings {
            if anchorName.contains(pairing.anchorMatchPhrase) {
                let alreadyHas = activeHabits.contains { existing in
                    existing.name.lowercased() == pairing.suggestedTemplate.name.lowercased()
                }
                if alreadyHas { continue }
                return CoachPairing(
                    anchorHabit: anchorHabit,
                    suggestedTemplate: pairing.suggestedTemplate,
                    headline: pairing.headline,
                    rationale: pairing.rationale
                )
            }
        }
        return nil
    }

    // MARK: Internal mapping table

    private struct Mapping {
        let anchorMatchPhrase: String
        let suggestedTemplateID: String
        let headline: String
        let rationale: String

        var suggestedTemplate: HabitTemplate {
            HabitTemplates.all.first { $0.id == suggestedTemplateID }
                ?? HabitTemplates.all[0]
        }
    }

    private static let mappings: [Mapping] = [
        .init(
            anchorMatchPhrase: "meds",
            suggestedTemplateID: "hydrate",
            headline: "Drink water — right after meds.",
            rationale: "Stacking on an existing routine has 2× the stick-rate."
        ),
        .init(
            anchorMatchPhrase: "water",
            suggestedTemplateID: "breath_one_min",
            headline: "One-minute breath — before your first email.",
            rationale: "Pairing breath with a transition softens the start of work."
        ),
        .init(
            anchorMatchPhrase: "breath",
            suggestedTemplateID: "move",
            headline: "Move 5 min — right after your breath.",
            rationale: "Two anchored transitions in a row build morning momentum."
        ),
        .init(
            anchorMatchPhrase: "wake",
            suggestedTemplateID: "hydrate",
            headline: "Drink water — first thing after waking.",
            rationale: "Hydration on top of waking is one of the stickiest combos."
        ),
        .init(
            anchorMatchPhrase: "sleep",
            suggestedTemplateID: "wind_down",
            headline: "Evening wind-down — 30 min before bed.",
            rationale: "Anchoring wind-down to bedtime makes both easier."
        ),
        .init(
            anchorMatchPhrase: "lights",
            suggestedTemplateID: "wind_down",
            headline: "Evening wind-down — before lights out.",
            rationale: "Anchoring wind-down to bedtime makes both easier."
        ),
        .init(
            anchorMatchPhrase: "move",
            suggestedTemplateID: "hydrate",
            headline: "Drink water — after you move.",
            rationale: "Stacking hydration on movement is automatic recovery."
        )
    ]
}

struct CoachPairing: Identifiable, Hashable {
    let id = UUID()
    let anchorHabit: Habit
    let suggestedTemplate: HabitTemplate
    let headline: String
    let rationale: String

    static func == (lhs: CoachPairing, rhs: CoachPairing) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
