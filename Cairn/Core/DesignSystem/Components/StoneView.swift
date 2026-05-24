import SwiftUI

// MARK: - Stone shape
struct StoneShape: Shape {
    var flatness: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY - h * (flatness * 0.18)

        let topY = rect.minY
        let bottomY = rect.maxY
        let leftX = rect.minX
        let rightX = rect.maxX

        p.move(to: CGPoint(x: leftX, y: cy))
        p.addCurve(
            to: CGPoint(x: rightX, y: cy),
            control1: CGPoint(x: leftX + w * 0.18, y: topY),
            control2: CGPoint(x: rightX - w * 0.22, y: topY)
        )

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
struct StoneView: View {
    var tint: Color = .stoneFill
    var width: CGFloat = 160
    var highlightStrength: Double = 0.55

    private var height: CGFloat { width * 0.58 }

    var body: some View {
        ZStack {
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

            Ellipse()
                .fill(Color.white.opacity(highlightStrength))
                .frame(width: width * 0.22, height: height * 0.18)
                .blur(radius: 6)
                .offset(x: -width * 0.18, y: -height * 0.22)

            StoneShape()
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        .compositingGroup()
    }
}

// MARK: - Ripple
struct StoneRippleView: View {
    var width: CGFloat = 160
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
        let effectivePhase = max(0, phase - delayed)
        let appliedScale = 1.0 + effectivePhase * (scale - 1.0)
        let appliedOpacity = opacity * Double(min(1, effectivePhase * 4))
        return Ellipse()
            .stroke(Color.textPrimary.opacity(appliedOpacity), lineWidth: 1)
            .scaleEffect(appliedScale, anchor: .center)
    }
}

// MARK: - Animated stone (drop + bounce + ripple)
struct AnimatedStoneView<T: Equatable>: View {
    var tint: Color = .stoneFill
    var width: CGFloat = 160
    var trigger: T
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
        dropOffset = -120
        dropOpacity = 0
        landScale = 0.92
        ripplePhase = 0

        if reduceMotion {
            dropOffset = 0
            dropOpacity = 1
            landScale = 1
            onLanded?()
            return
        }

        withAnimation(.easeOut(duration: 0.18)) {
            dropOpacity = 1
        }

        withAnimation(.timingCurve(0.32, 0.0, 0.68, 1.0, duration: 0.42)) {
            dropOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                landScale = 1.06
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    landScale = 1.0
                }
                onLanded?()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.easeOut(duration: 1.2)) {
                ripplePhase = 1
            }
        }
    }
}

// MARK: - Resting variant (no animation, for static contexts)
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
