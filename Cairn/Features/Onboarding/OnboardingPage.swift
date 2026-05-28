import Foundation
import SwiftUI

struct OnboardingPage: Identifiable {
    enum Hero {
        case symbol(name: String, color: Color)
        case stackedStones
        case singleStone
        case nameField
        case stateStone(StateStone.Kind)
    }

    let id = UUID()
    let hero: Hero
    let eyebrow: String?
    let headline: String
    /// Optional italic-sage accent line shown under the headline (the
    /// "calmer way / nothing breaks" beat the rest of the app uses).
    let accent: String?
    let subhead: String
    let ctaTitle: String

    init(
        hero: Hero,
        eyebrow: String? = nil,
        headline: String,
        accent: String? = nil,
        subhead: String,
        ctaTitle: String
    ) {
        self.hero = hero
        self.eyebrow = eyebrow
        self.headline = headline
        self.accent = accent
        self.subhead = subhead
        self.ctaTitle = ctaTitle
    }

    /// The onboarding deliberately surfaces the **comeback** framing at page
    /// three — early, not buried behind a miss the user might never reach.
    /// Quiet-hours / notification details belong in Settings, not here.
    static let all: [OnboardingPage] = [
        .init(
            hero: .symbol(name: "mountain.2.fill", color: .accentSage),
            eyebrow: "CAIRN",
            headline: "A calmer way",
            accent: "to keep showing up.",
            subhead: "Built for ADHD brains and anyone tired of streak-shaming apps. Gentle structure, not pressure.",
            ctaTitle: "Begin"
        ),
        .init(
            hero: .stackedStones,
            eyebrow: "STONES, NOT STREAKS",
            headline: "Every habit you place",
            accent: "adds a stone.",
            subhead: "Your stones stay — even after a missed day. You never get reset to zero.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .stateStone(.returning),
            eyebrow: "THE PART THAT MATTERS",
            headline: "Miss a day?",
            accent: "Nothing breaks here.",
            subhead: "Returning is the actual skill — not never missing. Cairn quietly celebrates the comeback.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .nameField,
            eyebrow: "A NAME FOR THE GARDEN",
            headline: "What should",
            accent: "we call you?",
            subhead: "Just for the welcome line. You can change it any time in Settings.",
            ctaTitle: "Continue"
        ),
        .init(
            hero: .singleStone,
            eyebrow: "READY?",
            headline: "Place your",
            accent: "first stone.",
            subhead: "Pick something tiny. One habit. You can always add more.",
            ctaTitle: "Pick a habit"
        )
    ]
}
