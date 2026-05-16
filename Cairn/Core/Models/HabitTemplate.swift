import Foundation

struct HabitTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: HabitCategory
    let iconName: String
    let colorTokenName: String
    let suggestedHour: Int?
    let suggestedMinute: Int?
    /// Long-form supportive copy shown in the full template grid.
    let blurb: String
    /// Short cue-anchor copy shown in compact contexts (e.g. gentle starters row).
    let cue: String?

    init(
        id: String,
        name: String,
        category: HabitCategory,
        iconName: String,
        colorTokenName: String,
        suggestedHour: Int?,
        suggestedMinute: Int?,
        blurb: String,
        cue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.iconName = iconName
        self.colorTokenName = colorTokenName
        self.suggestedHour = suggestedHour
        self.suggestedMinute = suggestedMinute
        self.blurb = blurb
        self.cue = cue
    }
}

enum HabitTemplates {
    /// IDs of the three curated "gentle starters" shown on the first-time Today screen.
    /// Order is intentional — meds first (highest-impact for ADHD), then anchor habits.
    static let gentleStarterIDs: [String] = [
        "meds_morning",
        "hydrate",
        "breath_one_min"
    ]

    /// Returns the three starter templates in the order defined by `gentleStarterIDs`.
    /// Missing IDs are skipped silently (defensive — should not happen in v1.0).
    static var gentleStarters: [HabitTemplate] {
        gentleStarterIDs.compactMap { id in all.first { $0.id == id } }
    }

    static let all: [HabitTemplate] = [
        .init(id: "meds_morning", name: "Morning meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 8, suggestedMinute: 30,
              blurb: "Same time, same place. Takes the choice out of it.",
              cue: "With breakfast"),

        .init(id: "meds_evening", name: "Evening meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 21, suggestedMinute: 0,
              blurb: "Wind-down dose. Pair with a fixed cue if you can.",
              cue: "After dinner"),

        .init(id: "sleep_window", name: "Lights out", category: .sleep,
              iconName: "moon.zzz.fill", colorTokenName: "accent.sky",
              suggestedHour: 23, suggestedMinute: 0,
              blurb: "Phone away, lights low. Sleep multiplies executive function.",
              cue: "Phone in another room"),

        .init(id: "wake", name: "Wake by", category: .sleep,
              iconName: "sunrise.fill", colorTokenName: "accent.coral",
              suggestedHour: 7, suggestedMinute: 30,
              blurb: "Steady wake time matters more than sleep time.",
              cue: "Same time daily"),

        .init(id: "hydrate", name: "Drink water", category: .water,
              iconName: "drop.fill", colorTokenName: "accent.sky",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Fill the bottle in the morning. The bottle is the cue.",
              cue: "Bottle by the sink"),

        .init(id: "move", name: "Move 5 min", category: .movement,
              iconName: "figure.walk", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Five minutes counts. Walks count. Stretching counts.",
              cue: "After the first coffee"),

        .init(id: "focus_block", name: "Focus block", category: .focus,
              iconName: "brain.head.profile", colorTokenName: "accent.sage",
              suggestedHour: 10, suggestedMinute: 0,
              blurb: "One block. Don't pick the topic now — pick it when the timer starts.",
              cue: "Phone face-down"),

        .init(id: "transition", name: "Transition pause", category: .transition,
              iconName: "arrow.triangle.swap", colorTokenName: "semantic.gentle",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "30 seconds between tasks. Stand, breathe, decide what's next.",
              cue: "Between tasks"),

        .init(id: "screen_break", name: "Screen break", category: .movement,
              iconName: "eye.fill", colorTokenName: "accent.sky",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Look at something far away for 20 seconds. Eyes will thank you.",
              cue: "Every hour"),

        .init(id: "hyperfocus_check", name: "Hyperfocus check-in", category: .hyperfocusCheckIn,
              iconName: "eye.trianglebadge.exclamationmark.fill", colorTokenName: "accent.coral",
              suggestedHour: 14, suggestedMinute: 0,
              blurb: "Eating? Hydrating? Locked in by choice or by lock?",
              cue: "Mid-afternoon"),

        .init(id: "nourish", name: "Eat a meal", category: .custom,
              iconName: "fork.knife", colorTokenName: "semantic.gentle",
              suggestedHour: 12, suggestedMinute: 30,
              blurb: "Meds + dopamine can mute hunger. Eat anyway.",
              cue: "Lunch alarm"),

        .init(id: "wind_down", name: "Evening wind-down", category: .transition,
              iconName: "moon.fill", colorTokenName: "accent.sky",
              suggestedHour: 22, suggestedMinute: 0,
              blurb: "Dim the lights. Put the phone in another room if you can.",
              cue: "After the last meal"),

        .init(id: "breath_one_min", name: "One-minute breath", category: .transition,
              iconName: "wind", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "One minute in, one minute out. The nervous system listens fast.",
              cue: "Before email"),
    ]
}
