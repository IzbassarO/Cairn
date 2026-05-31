import Foundation

struct HabitTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: HabitCategory
    let iconName: String
    let colorTokenName: String
    let suggestedHour: Int?
    let suggestedMinute: Int?
    let blurb: String
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
    static let gentleStarterIDs: [String] = [
        "meds_morning",
        "hydrate",
        "breath_one_min"
    ]

    static var gentleStarters: [HabitTemplate] {
        gentleStarterIDs.compactMap { id in all.first { $0.id == id } }
    }

    static let all: [HabitTemplate] = [
        // MARK: Meds

        .init(id: "meds_morning", name: "Morning meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 8, suggestedMinute: 30,
              blurb: "Same time, same place. Takes the choice out of it.",
              cue: "With breakfast"),

        .init(id: "meds_midday", name: "Midday meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 12, suggestedMinute: 30,
              blurb: "Pair it with lunch so the cue never moves.",
              cue: "With lunch"),

        .init(id: "meds_evening", name: "Evening meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 21, suggestedMinute: 0,
              blurb: "Wind-down dose. Pair with a fixed cue if you can.",
              cue: "After dinner"),

        // MARK: Sleep

        .init(id: "wake", name: "Wake by", category: .sleep,
              iconName: "sunrise.fill", colorTokenName: "accent.coral",
              suggestedHour: 7, suggestedMinute: 30,
              blurb: "Steady wake time matters more than sleep time.",
              cue: "Same time daily"),

        .init(id: "sleep_window", name: "Lights out", category: .sleep,
              iconName: "moon.zzz.fill", colorTokenName: "accent.sky",
              suggestedHour: 23, suggestedMinute: 0,
              blurb: "Phone away, lights low. Sleep multiplies executive function.",
              cue: "Phone in another room"),

        .init(id: "phone_curfew", name: "Phone away by", category: .sleep,
              iconName: "iphone.slash", colorTokenName: "accent.sky",
              suggestedHour: 22, suggestedMinute: 0,
              blurb: "An hour before bed beats a perfect sleep app.",
              cue: "On the kitchen counter"),

        .init(id: "caffeine_cutoff", name: "Last caffeine", category: .sleep,
              iconName: "cup.and.saucer.fill", colorTokenName: "accent.coral",
              suggestedHour: 14, suggestedMinute: 0,
              blurb: "Caffeine half-life is long. 2pm is kinder to your sleep.",
              cue: "After lunch"),

        // MARK: Hydration

        .init(id: "hydrate", name: "Drink water", category: .water,
              iconName: "drop.fill", colorTokenName: "accent.sky",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Fill the bottle in the morning. The bottle is the cue.",
              cue: "Bottle by the sink"),

        .init(id: "glass_first", name: "Glass before coffee", category: .water,
              iconName: "drop.fill", colorTokenName: "accent.sky",
              suggestedHour: 7, suggestedMinute: 0,
              blurb: "Hydration before caffeine. Mood and meds both thank you.",
              cue: "Next to the kettle"),

        .init(id: "refill_bottle", name: "Refill the bottle", category: .water,
              iconName: "drop.triangle.fill", colorTokenName: "accent.sky",
              suggestedHour: 12, suggestedMinute: 30,
              blurb: "Top up at lunch and you'll drink it without thinking.",
              cue: "Returning from lunch"),

        // MARK: Movement

        .init(id: "move", name: "Move 5 min", category: .movement,
              iconName: "figure.walk", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Five minutes counts. Walks count. Stretching counts.",
              cue: "After the first coffee"),

        .init(id: "stretch", name: "Stretch 2 min", category: .movement,
              iconName: "figure.cooldown", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Neck, shoulders, hips. Wherever the chair lives.",
              cue: "Standing up from the desk"),

        .init(id: "walk_outside", name: "Walk outside", category: .movement,
              iconName: "leaf.fill", colorTokenName: "accent.sage",
              suggestedHour: 13, suggestedMinute: 0,
              blurb: "Daylight + motion is the cheapest mood lift there is.",
              cue: "After lunch"),

        .init(id: "screen_break", name: "Screen break", category: .movement,
              iconName: "eye.fill", colorTokenName: "accent.sky",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Look at something far away for 20 seconds. Eyes will thank you.",
              cue: "Every hour"),

        // MARK: Focus

        .init(id: "focus_block", name: "Focus block", category: .focus,
              iconName: "brain.head.profile", colorTokenName: "accent.sage",
              suggestedHour: 10, suggestedMinute: 0,
              blurb: "One block. Don't pick the topic now — pick it when the timer starts.",
              cue: "Phone face-down"),

        .init(id: "single_task", name: "Single-task hour", category: .focus,
              iconName: "rectangle.stack.fill", colorTokenName: "accent.sage",
              suggestedHour: 9, suggestedMinute: 30,
              blurb: "One tab, one task, one hour. Close everything else first.",
              cue: "Before opening email"),

        .init(id: "phone_face_down", name: "Phone face-down", category: .focus,
              iconName: "iphone.gen3.slash", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Out of sight is more than out of mind — it's out of pull.",
              cue: "Starting deep work"),

        // MARK: Transition

        .init(id: "morning_intention", name: "Morning intention", category: .transition,
              iconName: "sun.horizon.fill", colorTokenName: "accent.coral",
              suggestedHour: 8, suggestedMinute: 0,
              blurb: "One sentence about the day before the screens start asking.",
              cue: "Before the first scroll"),

        .init(id: "transition", name: "Transition pause", category: .transition,
              iconName: "arrow.triangle.swap", colorTokenName: "semantic.gentle",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "30 seconds between tasks. Stand, breathe, decide what's next.",
              cue: "Between tasks"),

        .init(id: "breath_one_min", name: "One-minute breath", category: .transition,
              iconName: "wind", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "One minute in, one minute out. The nervous system listens fast.",
              cue: "Before email"),

        .init(id: "wind_down", name: "Evening wind-down", category: .transition,
              iconName: "moon.fill", colorTokenName: "accent.sky",
              suggestedHour: 22, suggestedMinute: 0,
              blurb: "Dim the lights. Put the phone in another room if you can.",
              cue: "After the last meal"),

        // MARK: Hyperfocus check-ins

        .init(id: "hyperfocus_check", name: "Hyperfocus check-in", category: .hyperfocusCheckIn,
              iconName: "eye.trianglebadge.exclamationmark.fill", colorTokenName: "accent.coral",
              suggestedHour: 14, suggestedMinute: 0,
              blurb: "Eating? Hydrating? Locked in by choice or by lock?",
              cue: "Mid-afternoon"),

        .init(id: "body_check", name: "Body check-in", category: .hyperfocusCheckIn,
              iconName: "figure.mind.and.body", colorTokenName: "accent.coral",
              suggestedHour: 11, suggestedMinute: 0,
              blurb: "Shoulders down. Jaw soft. Feet on the floor.",
              cue: "Late morning"),

        .init(id: "mood_check", name: "Mood check-in", category: .hyperfocusCheckIn,
              iconName: "heart.text.square.fill", colorTokenName: "accent.coral",
              suggestedHour: 17, suggestedMinute: 0,
              blurb: "Name what you feel in one word. That's enough.",
              cue: "End of work block"),

        // MARK: Learning

        .init(id: "read_pages", name: "Read 5 pages", category: .learning,
              iconName: "book.fill", colorTokenName: "accent.sage",
              suggestedHour: 21, suggestedMinute: 30,
              blurb: "Five pages counts. Same chair, same time.",
              cue: "Before bed"),

        .init(id: "journal_line", name: "Journal one line", category: .learning,
              iconName: "pencil.line", colorTokenName: "accent.sage",
              suggestedHour: 20, suggestedMinute: 0,
              blurb: "One sentence about today. It doesn't have to be deep.",
              cue: "After dinner"),

        .init(id: "study_short", name: "Study 15 min", category: .learning,
              iconName: "graduationcap.fill", colorTokenName: "accent.sage",
              suggestedHour: 18, suggestedMinute: 0,
              blurb: "Set the timer. Start with the easiest topic.",
              cue: "Quiet corner"),

        .init(id: "plan_tomorrow", name: "Plan tomorrow", category: .learning,
              iconName: "list.bullet.clipboard.fill", colorTokenName: "accent.coral",
              suggestedHour: 20, suggestedMinute: 30,
              blurb: "Three things for tomorrow, no more. Future-you will know what to do.",
              cue: "After dinner cleanup"),

        // MARK: Tidy

        .init(id: "make_bed", name: "Make the bed", category: .tidy,
              iconName: "bed.double.fill", colorTokenName: "accent.sky",
              suggestedHour: 8, suggestedMinute: 15,
              blurb: "First win of the day, before anyone asks anything of you.",
              cue: "After waking"),

        .init(id: "quick_reset", name: "Quick reset", category: .tidy,
              iconName: "sparkles", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Five minutes, one surface. Don't tidy the whole room.",
              cue: "Before bed"),

        .init(id: "inbox_sweep", name: "Inbox sweep", category: .tidy,
              iconName: "tray.fill", colorTokenName: "accent.sky",
              suggestedHour: 17, suggestedMinute: 0,
              blurb: "Archive ten. No replies needed. Close the loop, close the laptop.",
              cue: "End of the workday"),

        // MARK: Other

        .init(id: "nourish", name: "Eat a meal", category: .custom,
              iconName: "fork.knife", colorTokenName: "semantic.gentle",
              suggestedHour: 12, suggestedMinute: 30,
              blurb: "Meds + dopamine can mute hunger. Eat anyway.",
              cue: "Lunch alarm"),

        .init(id: "vitamin", name: "Take a vitamin", category: .custom,
              iconName: "leaf.circle.fill", colorTokenName: "accent.sage",
              suggestedHour: 8, suggestedMinute: 30,
              blurb: "Stack it next to your meds bottle. One cue, two habits.",
              cue: "With morning meds"),
    ]
}
