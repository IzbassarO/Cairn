import SwiftUI

/// Compact stone visual for the "TODAY'S CAIRN" card. Two shapes:
///  - `.resting` (0 placed): one small stone with a faint ripple beneath
///  - `.stacking(placed: Int)`: up to 3 stones stacked, ripple beneath
///
/// We deliberately cap the visible stones at 3. The design intent (and the
/// future Free-tier limit) is that the cairn stays readable at a glance —
/// not a tower of identical pebbles.
struct TodayCairnHero: View {
    enum State {
        case resting
        case stacking(placed: Int)
    }

    var state: State
    /// Total visual width of the cairn (the ripple's outer ellipse).
    var width: CGFloat = 110

    /// Maximum number of stones we draw, regardless of `placed` count.
    private let maxVisibleStones = 3

    /// Animation trigger for stone landing — incremented externally if you
    /// want to replay the "drop" effect. Otherwise the stone is drawn at rest.
    var landTrigger: Int = 0

    var body: some View {
        ZStack {
            switch state {
            case .resting:
                singleStone
            case .stacking(let placed):
                stackedStones(placedCount: max(0, placed))
            }
        }
        .frame(width: width, height: heroHeight)
    }

    // MARK: Heights

    private var heroHeight: CGFloat { width * 0.78 }

    // MARK: Resting state — one small stone + faint ripple
    // Used when the user has habits but hasn't logged anything today.

    private var singleStone: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            StoneView(tint: .stoneFill, width: width * 0.55)
            staticRipple
                .padding(.top, 2)
        }
        .accessibilityHidden(true)
    }

    // MARK: Stacking state — up to 3 stones + ripple
    // The top stone is the smallest, the bottom is the largest. We use
    // alternating accent tints so the stack reads as multiple stones.

    private func stackedStones(placedCount: Int) -> some View {
        // How many stones to draw: `placedCount` clamped to [1, 3]. We never
        // draw zero stones in `.stacking` — that's what `.resting` is for.
        let visible = max(1, min(placedCount, maxVisibleStones))

        return VStack(spacing: -2) {
            Spacer(minLength: 0)

            // Top → bottom. Top is the most recent, smallest stone.
            ForEach(0..<visible, id: \.self) { i in
                // i=0 is topmost; bottom stone is widest.
                let widthRatio = 0.42 + CGFloat(i) * 0.10
                let tint = tint(for: i)
                StoneView(tint: tint, width: width * widthRatio)
                    .transition(.scale.combined(with: .opacity))
                    .id("stone-\(i)-\(landTrigger)")
            }

            staticRipple
                .padding(.top, 2)
        }
        .accessibilityHidden(true)
    }

    private func tint(for index: Int) -> Color {
        // Alternate so the stack reads as distinct stones.
        switch index % 3 {
        case 0: return Color.stoneFill            // topmost — warm beige
        case 1: return Color.accentSage           // middle — sage
        default: return Color.stoneFill.opacity(0.85)
        }
    }

    // MARK: Static ripple (no animation — this is a calm at-rest visual)

    private var staticRipple: some View {
        ZStack {
            rippleLine(scale: 1.0, opacity: 0.18)
            rippleLine(scale: 1.4, opacity: 0.11)
            rippleLine(scale: 1.85, opacity: 0.06)
        }
        .frame(width: width * 0.85, height: width * 0.18)
    }

    private func rippleLine(scale: CGFloat, opacity: Double) -> some View {
        Ellipse()
            .stroke(Color.textPrimary.opacity(opacity), lineWidth: 1)
            .frame(width: width * 0.6, height: width * 0.15)
            .scaleEffect(scale, anchor: .center)
    }
}
