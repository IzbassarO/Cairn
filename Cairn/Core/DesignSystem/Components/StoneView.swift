import SwiftUI

// MARK: - Stone shape
// An asymmetric, pebble-like oval. Slightly flatter on the bottom, gentle bulge on top.
struct StoneShape: Shape {
    /// 0…1 — controls the bottom flatness. 0 = pure ellipse, 1 = quite flat.
    var flatness: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        // Push the visual center slightly upward so the bottom looks "settled".
        let cy = rect.midY - h * (flatness * 0.18)

        let topY = rect.minY
        let bottomY = rect.maxY
        let leftX = rect.minX
        let rightX = rect.maxX

        // Top curve — full bulge.
        p.move(to: CGPoint(x: leftX, y: cy))
        p.addCurve(
            to: CGPoint(x: rightX, y: cy),
            control1: CGPoint(x: leftX + w * 0.18, y: topY),
            control2: CGPoint(x: rightX - w * 0.22, y: topY)
        )

        // Bottom curve — flatter, controls pulled inward and downward less than the top.
        let bottomDepth = bottomY - h * flatness * 0.35
        p.addCurve(
            to: CGPoint(x: leftX, y: cy),
            control1: CGPoint(x: rightX - w * 0.16, y: bottomDepth),
            control2: CGPoint(x: leftX + w * 0.20, y: bottomDepth)
        )

        return p
    }
}

// MARK: - Stone view
// Renders a single stone with body gradient, soft top highlight, and drop shadow.
// Use `tint` to pick the stone's base color (sage by default to match v1.0 brand).
struct StoneView: View {
    var tint: Color = .stoneFill
    /// Width of the stone in points. Height is derived from aspect (≈ 0.58 of width).
    var width: CGFloat = 160
    /// Specular highlight strength, 0…1.
    var highlightStrength: Double = 0.55

    private var height: CGFloat { width * 0.58 }

    var body: some View {
        ZStack {
            // Body fill
            StoneShape()
                .fill(
                    LinearGradient(
                        colors: [
                            tint,
                            tint.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Specular highlight (small ellipse near the top-left, soft-blurred)
            Ellipse()
                .fill(Color.white.opacity(highlightStrength))
                .frame(width: width * 0.22, height: height * 0.18)
                .blur(radius: 6)
                .offset(x: -width * 0.18, y: -height * 0.22)

            // Subtle outline for definition on light backgrounds
            StoneShape()
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        .compositingGroup()
    }
}

// MARK: - Ripple
// Three concentric rings that expand and fade. Driven by a `phase` 0…1.
struct StoneRippleView: View {
    /// Width matches the stone's footprint.
    var width: CGFloat = 160
    /// 0 = at-rest (rings invisible), 1 = fully expanded.
    var phase: CGFloat = 0

    var body: some View {
        ZStack {
            ring(scale: 1.0 + phase * 0.35, opacity: (1 - phase) * 0.35)
            ring(scale: 1.0 + phase * 0.65, opacity: (1 - phase) * 0.22, delayed: 0.15)
            ring(scale: 1.0 + phase * 0.95, opacity: (1 - phase) * 0.14, delayed: 0.30)
        }
        .frame(width: width, height: width * 0.34)
        .allowsHitTesting(false)
    }

    private func ring(scale: CGFloat, opacity: Double, delayed: CGFloat = 0) -> some View {
        // `delayed` shifts the ring's appearance so the three feel staggered.
        let effectivePhase = max(0, phase - delayed)
        let appliedScale = 1.0 + effectivePhase * (scale - 1.0)
        let appliedOpacity = opacity * Double(min(1, effectivePhase * 4))
        return Ellipse()
            .stroke(Color.textPrimary.opacity(appliedOpacity), lineWidth: 1)
            .scaleEffect(appliedScale, anchor: .center)
    }
}

// MARK: - Animated stone (drop + bounce + ripple)
// Self-contained "place a stone" animation. Stone falls from above, lands, ripples expand.
// Use `trigger` to replay (any value change replays the animation).
struct AnimatedStoneView<T: Equatable>: View {
    var tint: Color = .stoneFill
    var width: CGFloat = 160
    /// Change this value to replay the animation.
    var trigger: T
    /// Called when the stone finishes its landing bounce (ripples may still be fading).
    var onLanded: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dropOffset: CGFloat = -120
    @State private var dropOpacity: Double = 0
    @State private var landScale: CGFloat = 0.92
    @State private var ripplePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            StoneView(tint: tint, width: width)
                .scaleEffect(x: 1.0, y: landScale, anchor: .bottom)
                .offset(y: dropOffset)
                .opacity(dropOpacity)

            StoneRippleView(width: width, phase: ripplePhase)
                .padding(.top, 4)
        }
        .onAppear { runAnimation() }
        .onChange(of: trigger) { _, _ in runAnimation() }
        .accessibilityHidden(true)
    }

    private func runAnimation() {
        // Reset.
        dropOffset = -120
        dropOpacity = 0
        landScale = 0.92
        ripplePhase = 0

        if reduceMotion {
            // Settle instantly, no bounce, no ripple.
            dropOffset = 0
            dropOpacity = 1
            landScale = 1
            onLanded?()
            return
        }

        // Fade-in during the drop.
        withAnimation(.easeOut(duration: 0.18)) {
            dropOpacity = 1
        }

        // Fall.
        withAnimation(.timingCurve(0.32, 0.0, 0.68, 1.0, duration: 0.42)) {
            dropOffset = 0
        }

        // Landing squash → settle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                landScale = 1.06
            }
            // Bounce back to natural height.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    landScale = 1.0
                }
                onLanded?()
            }
        }

        // Ripple kicks off the moment the stone makes contact.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.easeOut(duration: 1.2)) {
                ripplePhase = 1
            }
        }
    }
}

// MARK: - Resting variant (no animation, for static contexts)
// Stone + faint static ripple lines beneath. Used on the first-time Today screen.
struct RestingStoneView: View {
    var tint: Color = .stoneFill
    var width: CGFloat = 160

    var body: some View {
        VStack(spacing: 0) {
            StoneView(tint: tint, width: width)
            StaticRippleLines(width: width)
                .padding(.top, 4)
        }
        .accessibilityHidden(true)
    }
}

private struct StaticRippleLines: View {
    var width: CGFloat

    var body: some View {
        ZStack {
            line(scale: 1.0, opacity: 0.18)
            line(scale: 1.35, opacity: 0.12)
            line(scale: 1.75, opacity: 0.07)
        }
        .frame(width: width, height: width * 0.32)
    }

    private func line(scale: CGFloat, opacity: Double) -> some View {
        Ellipse()
            .stroke(Color.textPrimary.opacity(opacity), lineWidth: 1)
            .frame(width: width * 0.78, height: width * 0.22)
            .scaleEffect(scale, anchor: .center)
    }
}
