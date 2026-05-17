import SwiftUI

/// Visual stones placed today. Sits between the header and TodayCairnCard.
///
/// Empty state (no logs yet today): faint outlined stone silhouettes with a
/// quiet caption. Always rendered — the user knows where their stones will
/// land before they earn any.
///
/// Filled state: one stone per habit logged today (we count uniquely by
/// habit, not by log — multi-target habits don't create duplicate stones).
/// Stones are arranged in a casual horizontal row of varied sizes, not a
/// strict cairn pyramid.
struct StonesWidget: View {
    /// Habits the user has logged at least once today. Order doesn't matter
    /// — we lay them out by their identity hash for visual stability.
    let placedHabits: [Habit]
    /// Total habits scheduled today (for the empty-state caption, e.g.
    /// "3 stones waiting").
    let totalScheduledToday: Int

    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary.opacity(0.55))
                .frame(height: cardHeight)

            if placedHabits.isEmpty {
                emptyState
            } else {
                stonesPile
            }
        }
    }

    private var cardHeight: CGFloat { 110 }

    // MARK: Empty state

    private var emptyState: some View {
        HStack(spacing: Spacing.md) {
            silhouettesRow
            Text(emptyCaption)
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var emptyCaption: String {
        switch totalScheduledToday {
        case 0: return "Plant a habit to start your cairn."
        case 1: return "Today's first stone is waiting."
        default: return "Today's stones will appear here."
        }
    }

    /// Three outlined faint silhouettes — pure decoration, never logs.
    private var silhouettesRow: some View {
        HStack(spacing: -6) {
            stoneSilhouette(width: 34)
            stoneSilhouette(width: 42)
            stoneSilhouette(width: 30)
        }
        .opacity(0.55)
    }

    private func stoneSilhouette(width: CGFloat) -> some View {
        Ellipse()
            .strokeBorder(
                Color.textTertiary,
                style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
            )
            .frame(width: width, height: width * 0.72)
    }

    // MARK: Filled state

    private var stonesPile: some View {
        // Horizontal pile. Stones overlap slightly (negative spacing) and use
        // alternating sizes so the pile feels organic, not gridded.
        HStack(spacing: -8) {
            ForEach(Array(placedHabits.enumerated()), id: \.element.id) { index, habit in
                StoneView(
                    tint: tintForIndex(index),
                    width: widthForIndex(index)
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    /// Alternates between sage and beige stones, slightly biased so the
    /// majority are warm-beige. Three-color rotation.
    private func tintForIndex(_ i: Int) -> Color {
        switch i % 3 {
        case 0: return .stoneFill
        case 1: return .accentSage
        default: return .stoneFill.opacity(0.85)
        }
    }

    /// Stones grow toward the middle of the pile (visual "cairn" shape).
    /// Indices 0 and last get smaller widths.
    private func widthForIndex(_ i: Int) -> CGFloat {
        let count = placedHabits.count
        guard count > 1 else { return 56 }
        let mid = Double(count - 1) / 2.0
        let dist = abs(Double(i) - mid) / max(mid, 1)
        // dist=0 (center) → biggest, dist=1 (edge) → smallest
        return 42 + (1.0 - dist) * 22
    }
}
