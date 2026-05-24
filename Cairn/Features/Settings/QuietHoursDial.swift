import SwiftUI
import CoreGraphics

// MARK: - QuietHoursDial
//
// A 24-hour circular dial with two draggable handles (start = moon, end = sun)
// and the quiet duration in the center. Hour 0 (midnight) sits at the top and
// time runs clockwise, so the arc from start→end (clockwise) is the quiet
// window — even when it wraps past midnight.
//
// Hours are whole numbers 0–23 to match the existing AppStorage model. Dragging
// snaps to the nearest hour for a calm, deliberate feel.

struct QuietHoursDial: View {
    @Binding var startHour: Int
    @Binding var endHour: Int

    /// Which handle is currently being dragged (nil when idle).
    @State private var activeHandle: Handle? = nil

    private enum Handle { case start, end }

    private let ringWidth: CGFloat = 8
    private let handleSize: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = (size - handleSize) / 2
            let center = CGPoint(x: geo.size.width / 2, y: size / 2)

            ZStack {
                // Base ring
                Circle()
                    .stroke(Color.bgTertiary.opacity(0.5), lineWidth: ringWidth)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Quiet arc (start → end, clockwise)
                Circle()
                    .trim(from: 0, to: arcFraction)
                    .stroke(Color.accentSage, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(angle(for: startHour) - 90))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Hour labels at the 3-hour marks
                ForEach(Array(stride(from: 0, to: 24, by: 3)), id: \.self) { h in
                    let p = point(for: Double(h), radius: radius - ringWidth - 16, center: center)
                    Text("\(h)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.textTertiary)
                        .position(p)
                }

                // Center duration
                VStack(spacing: 2) {
                    Text("\(quietSpanHours)h")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                    Text("OF QUIET")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color.textTertiary)
                }
                .position(center)

                // Start handle (moon)
                handle(systemName: "moon.fill", filled: true)
                    .position(point(for: Double(startHour), radius: radius, center: center))
                    .gesture(dragGesture(for: .start, center: center, radius: radius))

                // End handle (sun)
                handle(systemName: "sun.max.fill", filled: false)
                    .position(point(for: Double(endHour), radius: radius, center: center))
                    .gesture(dragGesture(for: .end, center: center, radius: radius))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Handle view

    private func handle(systemName: String, filled: Bool) -> some View {
        ZStack {
            Circle()
                .fill(filled ? Color.accentSage : Color.white)
                .overlay(Circle().strokeBorder(Color.accentSage, lineWidth: filled ? 0 : 2))
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(filled ? Color.white : Color.accentSage)
        }
        .frame(width: handleSize, height: handleSize)
    }

    // MARK: Geometry

    /// Degrees clockwise from midnight (top). 24h → 360°.
    private func angle(for hour: Int) -> Double {
        Double(hour) / 24.0 * 360.0
    }

    /// Point on the ring for a given hour. 0 at top, clockwise.
    private func point(for hour: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = (hour / 24.0 * 360.0 - 90.0) * .pi / 180.0
        return CGPoint(x: center.x + radius * cos(radians),
                       y: center.y + radius * sin(radians))
    }

    /// Fraction of the full circle covered by the quiet window (clockwise).
    private var arcFraction: CGFloat {
        CGFloat(quietSpanHours) / 24.0
    }

    private var quietSpanHours: Int {
        let raw = endHour - startHour
        return raw > 0 ? raw : raw + 24
    }

    // MARK: Drag

    private func dragGesture(for handle: Handle, center: CGPoint, radius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                activeHandle = handle
                let hour = hourFromPoint(value.location, center: center)
                switch handle {
                case .start: if hour != startHour { startHour = hour }
                case .end:   if hour != endHour { endHour = hour }
                }
            }
            .onEnded { _ in activeHandle = nil }
    }

    /// Convert a touch point to the nearest whole hour (0–23), 0 at top clockwise.
    private func hourFromPoint(_ p: CGPoint, center: CGPoint) -> Int {
        let dx = p.x - center.x
        let dy = p.y - center.y
        var degrees = atan2(dy, dx) * 180 / .pi + 90  // +90: shift so top = 0
        if degrees < 0 { degrees += 360 }
        let hour = Int((degrees / 360.0 * 24.0).rounded()) % 24
        return hour
    }
}
