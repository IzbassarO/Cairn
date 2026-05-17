import SwiftUI

/// Filter for the Today habit list. Three pills with counts:
///  - **All**: every active habit
///  - **Pending**: habits not yet placed today
///  - **Done**: habits already placed today
///
/// Selected pill is solid charcoal (`textPrimary`) with white text. The two
/// counts (`pending`, `done`) are pre-computed by the parent.
enum HabitFilter: String, CaseIterable {
    case all, pending, done
    var label: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .done: return "Done"
        }
    }
}

struct HabitFilterChips: View {
    @Binding var selected: HabitFilter
    let allCount: Int
    let pendingCount: Int
    let doneCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(HabitFilter.allCases, id: \.self) { filter in
                chip(for: filter)
            }
        }
    }

    private func chip(for filter: HabitFilter) -> some View {
        let isOn = selected == filter
        let count = count(for: filter)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                selected = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.label)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isOn ? Color.white.opacity(0.6) : Color.textTertiary)
            }
            .foregroundStyle(isOn ? Color.white : Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isOn ? Color.textPrimary : Color.bgSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private func count(for filter: HabitFilter) -> Int {
        switch filter {
        case .all: return allCount
        case .pending: return pendingCount
        case .done: return doneCount
        }
    }
}
