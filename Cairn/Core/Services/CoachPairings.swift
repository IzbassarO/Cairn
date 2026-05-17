import Foundation

/// Static mapping that defines "stacking" suggestions: given an existing
/// habit, which template should we suggest the user add next?
///
/// Used by N1 (Add another) to show the Coach Pairing card. The card only
/// shows while the user has ≤3 active habits — the pairing pattern is most
/// helpful early when the user is still anchoring habits to existing routines.
///
/// Design rationale:
///  - Mapping is hand-curated, not algorithmic. The combinations below are
///    "stacking on an existing routine" patterns from behavior-design lit
///    (hydrate after meds, breath before email, etc).
///  - Returns nil if no pairing applies — the card disappears, no card shown.
enum CoachPairings {

    /// Maximum number of active habits before pairings stop showing.
    /// At 4+ habits the user is past the "still anchoring" phase.
    static let pairingHabitCeiling = 3

    /// Suggested pairing for a freshly-loaded N1 screen.
    ///
    /// - Parameters:
    ///   - activeHabits: habits the user already has (we won't re-suggest these)
    /// - Returns: A pairing if one applies, else nil.
    static func suggest(for activeHabits: [Habit]) -> CoachPairing? {
        // Don't suggest pairings to users past the ceiling — they're not
        // in the anchoring phase anymore.
        guard activeHabits.count <= pairingHabitCeiling,
              !activeHabits.isEmpty
        else { return nil }

        // Look at the user's first active habit (oldest, sortOrder = 0)
        // and propose the canonical pairing for it.
        let anchorHabit = activeHabits.sorted { $0.sortOrder < $1.sortOrder }.first!
        let anchorName = anchorHabit.name.lowercased()

        // Find a matching pairing whose anchor name matches the user's habit.
        // We match by name (case-insensitive) rather than template ID because
        // custom habits don't have template IDs but might still benefit from
        // a known pairing if the user named them obviously.
        for pairing in mappings {
            if anchorName.contains(pairing.anchorMatchPhrase) {
                // Don't suggest a template the user already has.
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
        let anchorMatchPhrase: String   // substring matched against habit.name.lowercased()
        let suggestedTemplateID: String
        let headline: String
        let rationale: String

        var suggestedTemplate: HabitTemplate {
            HabitTemplates.all.first { $0.id == suggestedTemplateID }
                ?? HabitTemplates.all[0] // safe fallback, should never hit
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

/// A concrete pairing suggestion ready to render in the Coach Pairing card.
struct CoachPairing: Identifiable, Hashable {
    let id = UUID()
    let anchorHabit: Habit
    let suggestedTemplate: HabitTemplate
    let headline: String
    let rationale: String

    static func == (lhs: CoachPairing, rhs: CoachPairing) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
