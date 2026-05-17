import SwiftUI

/// Small horizontal label that separates groups of habits in the Today list
/// when there are multiple categories represented (e.g. Morning, Hydrate).
/// Mockup T shows `☀ MORNING` on the left and `2/3` on the right.
struct HabitsCategoryHeader: View {
    let category: HabitCategory
    let placedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 11))
                .foregroundStyle(Color.accentSage)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
            Spacer()
            Text("\(placedCount)/\(totalCount)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.sm)
    }

    private var label: String {
        switch category {
        case .meds: return "Meds"
        case .water: return "Hydrate"
        case .movement: return "Move"
        case .focus: return "Focus"
        case .sleep: return "Wind down"
        case .transition: return "Transitions"
        case .hyperfocusCheckIn: return "Check-ins"
        case .custom: return "Other"
        }
    }

    private var iconName: String {
        switch category {
        case .meds: return "pills"
        case .water: return "drop"
        case .movement: return "figure.walk"
        case .focus: return "curlybraces"
        case .sleep: return "moon"
        case .transition: return "arrow.triangle.swap"
        case .hyperfocusCheckIn: return "eye"
        case .custom: return "sparkle"
        }
    }
}
