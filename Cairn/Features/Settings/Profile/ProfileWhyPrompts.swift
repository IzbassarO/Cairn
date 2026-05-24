import Foundation

enum ProfileWhyPrompts {
    static let all: [String] = [
        "Because small steps still count as steps.",
        "To be a little more here for the people I love.",
        "I'm building a life that feels like mine, one stone at a time.",
        "Not to fix myself — just to take care of myself.",
        "Because the days I show up gently are the ones I'm proud of.",
        "To prove to myself that consistency doesn't have to hurt.",
        "I want mornings that start calm instead of behind.",
        "Because my future self deserves a little kindness today.",
        "Progress isn't loud. It's quiet, and it's daily.",
        "I'm learning to work with my brain, not against it.",
        "Because returning after a missed day is its own kind of strength.",
        "To feel steady, even when everything else isn't."
    ]

    static func random(excluding current: String) -> String {
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        let pool = all.filter { $0 != trimmed }
        return (pool.isEmpty ? all : pool).randomElement() ?? all[0]
    }
}
