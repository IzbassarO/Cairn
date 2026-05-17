import SwiftUI

/// "fewer stones [···] more" legend under the calendar. Five sage dots from
/// light → dark mirror the intensity gradient used in the calendar cells.
struct GardenIntensityLegend: View {
    var body: some View {
        HStack {
            Text("fewer stones")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Color.accentSage.opacity(0.32 + Double(i) * 0.17))
                        .frame(width: 10, height: 10)
                }
            }
            Spacer()
            Text("more")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, Spacing.lg)
    }
}
