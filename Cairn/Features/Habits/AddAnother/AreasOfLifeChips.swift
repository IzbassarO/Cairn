import SwiftUI

/// Horizontal scroll of category chips for N1. Multi-select: tap to toggle.
/// Empty selection = "All categories" (the consumer view shows everything).
struct AreasOfLifeChips: View {
    @Binding var selected: Set<HabitCategory>

    /// Display order — UX choice (most-used categories first).
    /// Mirrors the categories present in HabitTemplates.all.
    private let displayCategories: [HabitCategory] = [
        .meds, .water, .movement, .focus, .sleep, .transition, .hyperfocusCheckIn, .custom
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(displayCategories, id: \.rawValue) { category in
                    chip(for: category)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .scrollClipDisabled()
    }

    private func chip(for category: HabitCategory) -> some View {
        let isOn = selected.contains(category)
        return Button {
            toggle(category)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconName(for: category))
                    .font(.system(size: 13, weight: .medium))
                Text(label(for: category))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isOn ? Color.white : Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isOn ? Color.textPrimary : Color.bgSecondary)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label(for: category)), \(isOn ? "selected" : "not selected")")
    }

    private func toggle(_ category: HabitCategory) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
            if selected.contains(category) {
                selected.remove(category)
            } else {
                selected.insert(category)
            }
        }
    }

    // MARK: Per-category label & icon

    private func label(for category: HabitCategory) -> String {
        switch category {
        case .meds: return "Meds"
        case .water: return "Hydrate"
        case .movement: return "Move"
        case .focus: return "Focus"
        case .sleep: return "Sleep"
        case .transition: return "Transition"
        case .hyperfocusCheckIn: return "Check-in"
        case .custom: return "Other"
        }
    }

    private func iconName(for category: HabitCategory) -> String {
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
