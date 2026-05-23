import Foundation

enum ReminderStyle: String, CaseIterable, Identifiable {
    case gentle = "gentle"
    case standard = "standard"
    case bold = "bold"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: return "Gentle nudge"
        case .standard: return "Standard"
        case .bold: return "Bold"
        }
    }

    var sampleText: String {
        switch self {
        case .gentle: return "When you're ready — your water is waiting."
        case .standard: return "Time for: Drink water"
        case .bold: return "Drink water now. Future-you will thank you."
        }
    }

    var description: String {
        switch self {
        case .gentle: return "Soft and opt-in. Best for low-energy mornings."
        case .standard: return "Direct and unfussy. Default behavior."
        case .bold: return "More urgent. Useful for habits that resist starting."
        }
    }

    var iconName: String {
        switch self {
        case .gentle: return "leaf"
        case .standard: return "bell"
        case .bold: return "bolt"
        }
    }
}
