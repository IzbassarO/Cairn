import SwiftUI

struct CairnView: View {
    let stoneCount: Int
    let daysActive: Int

    var maxVisible: Int = 7
    var baseStoneWidth: CGFloat = 140
    var stoneHeight: CGFloat = 22

    var body: some View {
        VStack(spacing: Spacing.md) {
            stoneStack
            label
        }
        .frame(maxWidth: .infinity)
    }

    private var stoneStack: some View {
        let visible = min(stoneCount, maxVisible)

        return VStack(spacing: 1) {
            if stoneCount == 0 {
                Capsule()
                    .stroke(Color.stoneFill.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .frame(width: baseStoneWidth, height: stoneHeight)
            } else {
                ForEach(0..<visible, id: \.self) { i in
                    let widthRatio = max(0.42, 1.0 - CGFloat(visible - 1 - i) * 0.10)
                    let tilt = sin(Double(i) * 1.7) * 2.5
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.stoneFill,
                                    Color.stoneFill.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: baseStoneWidth * widthRatio, height: stoneHeight)
                        .rotationEffect(.degrees(tilt))
                        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if stoneCount > maxVisible {
                Text("+\(stoneCount - maxVisible) more")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(height: 180, alignment: .bottom)
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: stoneCount)
    }

    private var label: some View {
        VStack(spacing: 2) {
            if stoneCount == 0 {
                Text("No stones yet")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                Text("Place your first when you're ready")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            } else {
                Text("\(stoneCount) stone\(stoneCount == 1 ? "" : "s") placed")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("across \(daysActive) day\(daysActive == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}
