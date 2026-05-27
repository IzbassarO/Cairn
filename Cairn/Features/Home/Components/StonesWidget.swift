import SwiftUI

/// Visual stones placed today. Sits between the header and TodayCairnCard.
///
/// Empty state (no logs yet today): faint outlined stone silhouettes with a
/// quiet caption. Always rendered — the user knows where their stones will
/// land before they earn any.
///
/// Filled state: one stone per habit logged today (we count uniquely by
/// habit, not by log — multi-target habits don't create duplicate stones).
/// Stones sit in an overlapping horizontal pile whose size adapts to fit the
/// card, so the row never overflows no matter how many habits are placed.
struct StonesWidget: View {
    /// Habits the user has logged at least once today. Order doesn't matter
    /// — we lay them out by their identity hash for visual stability.
    let placedHabits: [Habit]
    /// Total habits scheduled today (for the empty-state caption, e.g.
    /// "3 stones waiting").
    let totalScheduledToday: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary.opacity(0.55))

                if placedHabits.isEmpty {
                    emptyState
                } else {
                    stonesPile(available: geo.size.width - Spacing.lg * 2)
                }
            }
        }
        .frame(height: cardHeight)
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

    /// Horizontal pile that always fits the card. Stone size and overlap are
    /// derived from how many stones there are and how much width we have, so a
    /// busy day with many habits scales down instead of overflowing. When even
    /// the smallest stones won't all fit, we cap the row and add a "+N" badge.
    private func stonesPile(available: CGFloat) -> some View {
        let layout = pileLayout(count: placedHabits.count, available: available)
        return HStack(spacing: Spacing.sm) {
            HStack(spacing: -layout.overlap) {
                ForEach(0..<layout.visibleCount, id: \.self) { index in
                    StoneView(tint: tintForIndex(index), width: layout.stoneWidth)
                }
            }
            if layout.overflow > 0 {
                overflowBadge(layout.overflow, diameter: layout.stoneWidth)
            }
        }
    }

    private struct PileLayout {
        let stoneWidth: CGFloat
        let overlap: CGFloat
        let visibleCount: Int
        let overflow: Int
    }

    private func pileLayout(count: Int, available: CGFloat) -> PileLayout {
        let maxStone: CGFloat = 60
        let minStone: CGFloat = 30
        let overlapFraction: CGFloat = 0.30
        guard count > 0, available > 0 else {
            return PileLayout(stoneWidth: maxStone, overlap: maxStone * overlapFraction,
                              visibleCount: 0, overflow: 0)
        }
        // Width at which `n` stones (each overlapping the previous by
        // `overlapFraction`) span exactly `available`.
        func widthFitting(_ n: Int) -> CGFloat {
            let denom = CGFloat(n) * (1 - overlapFraction) + overlapFraction
            return available / denom
        }
        let ideal = min(maxStone, widthFitting(count))
        if ideal >= minStone {
            return PileLayout(stoneWidth: ideal, overlap: ideal * overlapFraction,
                              visibleCount: count, overflow: 0)
        }
        // Too many to show even at the minimum size: cap and reserve room for
        // the "+N" badge.
        let usable = max(0, available - (minStone + Spacing.sm))
        let raw = ((usable / minStone) - overlapFraction) / (1 - overlapFraction)
        let visible = max(1, min(count, Int(raw)))
        return PileLayout(stoneWidth: minStone, overlap: minStone * overlapFraction,
                          visibleCount: visible, overflow: count - visible)
    }

    private func overflowBadge(_ n: Int, diameter: CGFloat) -> some View {
        Text("+\(n)")
            .font(.system(size: max(12, diameter * 0.34), weight: .bold, design: .rounded))
            .foregroundStyle(Color.textSecondary)
            .frame(width: diameter, height: diameter * 0.58)
            .background(Capsule().fill(Color.bgTertiary))
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
}
