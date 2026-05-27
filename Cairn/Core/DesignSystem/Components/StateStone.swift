import SwiftUI
import UIKit

/// Renders a generated "state stone" emoji asset (e.g. `state-thriving`) with a
/// graceful SF Symbol fallback, so the UI stays intact before the images are
/// added to the asset catalog. Add the PNGs to Assets.xcassets named exactly:
/// state-thriving / state-steady / state-slipping / state-returning /
/// state-resting / state-milestone.
struct StateStone: View {
    enum Kind: String {
        case thriving = "state-thriving"
        case steady = "state-steady"
        case slipping = "state-slipping"
        case returning = "state-returning"
        case resting = "state-resting"
        case milestone = "state-milestone"

        var fallbackSymbol: String {
            switch self {
            case .thriving:  return "leaf.fill"
            case .steady:    return "leaf"
            case .slipping:  return "exclamationmark.circle"
            case .returning: return "arrow.uturn.backward"
            case .resting:   return "moon.zzz"
            case .milestone: return "sparkles"
            }
        }

        var fallbackColor: Color {
            switch self {
            case .slipping: return .accentCoral
            default:        return .accentSage
            }
        }
    }

    let kind: Kind
    var size: CGFloat = 32

    var body: some View {
        if UIImage(named: kind.rawValue) != nil {
            Image(kind.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: kind.fallbackSymbol)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(kind.fallbackColor)
                .frame(width: size, height: size)
        }
    }
}
