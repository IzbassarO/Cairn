import UIKit

// MARK: - HapticService

@MainActor
final class HapticService {
    static let shared = HapticService()
    private init() {}

    enum Feedback {
        /// A single habit logged — the core "I did it" moment.
        case stonePlaced
        /// Every stone for today is placed — the day is complete.
        case dayComplete
        /// A milestone reached (first stone, 10, 100…).
        case milestone
    }

    /// Play a feedback, but only when the user has haptics enabled.
    func play(_ feedback: Feedback, enabled: Bool) {
        guard enabled else { return }
        switch feedback {
        case .stonePlaced:
            // Soft, satisfying tap — like a pebble settling into place.
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare()
            g.impactOccurred()
        case .dayComplete:
            // A clear success chime — the day's cairn is finished.
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .milestone:
            // Same celebratory success as completing the day.
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
