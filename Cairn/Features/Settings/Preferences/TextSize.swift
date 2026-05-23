import SwiftUI

enum TextSize: String, CaseIterable, Identifiable {
    case small, standard, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .standard: return "Standard"
        case .large: return "Large"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .small: return .small
        case .standard: return nil
        case .large: return .xLarge
        }
    }
}
