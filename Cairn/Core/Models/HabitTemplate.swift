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
}

enum HabitTemplates {
    static let all: [HabitTemplate] = [
        .init(id: "meds_morning", name: "Morning meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 8, suggestedMinute: 30,
              blurb: "Same time, same place. Takes the choice out of it."),

        .init(id: "meds_evening", name: "Evening meds", category: .meds,
              iconName: "pills.fill", colorTokenName: "accent.coral",
              suggestedHour: 21, suggestedMinute: 0,
              blurb: "Wind-down dose. Pair with a fixed cue if you can."),

        .init(id: "sleep_window", name: "Lights out", category: .sleep,
              iconName: "moon.zzz.fill", colorTokenName: "accent.sky",
              suggestedHour: 23, suggestedMinute: 0,
              blurb: "Phone away, lights low. Sleep multiplies executive function."),

        .init(id: "wake", name: "Wake by", category: .sleep,
              iconName: "sunrise.fill", colorTokenName: "accent.coral",
              suggestedHour: 7, suggestedMinute: 30,
              blurb: "Steady wake time matters more than sleep time."),

        .init(id: "hydrate", name: "Drink water", category: .water,
              iconName: "drop.fill", colorTokenName: "accent.sky",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Fill the bottle in the morning. The bottle is the cue."),

        .init(id: "move", name: "Move 5 min", category: .movement,
              iconName: "figure.walk", colorTokenName: "accent.sage",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Five minutes counts. Walks count. Stretching counts."),

        .init(id: "focus_block", name: "Focus block", category: .focus,
              iconName: "brain.head.profile", colorTokenName: "accent.sage",
              suggestedHour: 10, suggestedMinute: 0,
              blurb: "One block. Don't pick the topic now — pick it when the timer starts."),

        .init(id: "transition", name: "Transition pause", category: .transition,
              iconName: "arrow.triangle.swap", colorTokenName: "semantic.gentle",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "30 seconds between tasks. Stand, breathe, decide what's next."),

        .init(id: "screen_break", name: "Screen break", category: .movement,
              iconName: "eye.fill", colorTokenName: "accent.sky",
              suggestedHour: nil, suggestedMinute: nil,
              blurb: "Look at something far away for 20 seconds. Eyes will thank you."),

        .init(id: "hyperfocus_check", name: "Hyperfocus check-in", category: .hyperfocusCheckIn,
              iconName: "eye.trianglebadge.exclamationmark.fill", colorTokenName: "accent.coral",
              suggestedHour: 14, suggestedMinute: 0,
              blurb: "Eating? Hydrating? Locked in by choice or by lock?"),

        .init(id: "nourish", name: "Eat a meal", category: .custom,
              iconName: "fork.knife", colorTokenName: "semantic.gentle",
              suggestedHour: 12, suggestedMinute: 30,
              blurb: "Meds + dopamine can mute hunger. Eat anyway."),

        .init(id: "wind_down", name: "Evening wind-down", category: .transition,
              iconName: "moon.fill", colorTokenName: "accent.sky",
              suggestedHour: 22, suggestedMinute: 0,
              blurb: "Dim the lights. Put the phone in another room if you can."),
    ]
}
