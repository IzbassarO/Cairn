import Foundation
import SwiftUI

struct OnboardingPage: Identifiable {
    enum Hero {
        case symbol(name: String, color: Color)
        case stackedStones
        case singleStone
        case nameField
    }

    let id = UUID()
    let hero: Hero
    let eyebrow: String?
    let headline: String
    let subhead: String
    let ctaTitle: String

    init(
        hero: Hero,
        eyebrow: String? = nil,
        headline: String,
        subhead: String,
        ctaTitle: String
    ) {
        self.hero = hero
        self.eyebrow = eyebrow
        self.headline = headline
        self.subhead = subhead
        self.ctaTitle = ctaTitle
    }

    static let all: [OnboardingPage] = [
        .init(
            hero: .symbol(name: "mountain.2.fill", color: .accentSage),
            headline: "Your brain just works differently.",
            subhead: "Cairn is built for ADHD. No streak shaming. No 47 features. Just gentle structure that respects your day.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .stackedStones,
            headline: "Stack stones, not pressure.",
            subhead: "Every habit you log adds a stone to your cairn. Miss a day? Your stones stay. We don't reset you to zero.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .symbol(name: "bell.fill", color: .accentCoral),
            headline: "Quiet reminders, not nags.",
            subhead: "Only nudges for habits where you want them. Time-sensitive for meds. Silent for the rest.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .nameField,
            eyebrow: "A NAME FOR THE GARDEN",
            headline: "What should we call you?",
            subhead: "It's just for the welcome line. You can change it any time in Settings.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .singleStone,
            headline: "Place your first stone.",
            subhead: "Pick something tiny. One habit. Start small — you can always add more.",
            ctaTitle: "Pick a habit"
        )
    ]
}
