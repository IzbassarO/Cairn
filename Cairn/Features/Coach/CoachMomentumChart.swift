import SwiftUI
import Charts

/// Interactive momentum chart for the Coach: stones over time, with a period
/// toggle (week / month / 6 months) and tap-to-inspect a bar. Styled to the
/// Cairn palette rather than Swift Charts' defaults.
///
/// New file — auto-included via the project's file-system-synchronized groups.
struct CoachMomentumChart: View {
    let insights: CoachInsights

    @State private var period: CoachInsights.TrendPeriod = .month
    @State private var selectedLabel: String?

    private var series: [CoachInsights.TrendPoint] { insights.momentumSeries(period) }
    private var total: Int { series.reduce(0) { $0 + $1.stones } }
    private var selected: CoachInsights.TrendPoint? {
        guard let selectedLabel else { return nil }
        return series.first { $0.label == selectedLabel }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            periodPicker
            if total == 0 {
                emptyNote
            } else {
                chart
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
        .onChange(of: period) { _, _ in selectedLabel = nil }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MOMENTUM")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.accentSage)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(selected?.stones ?? total)")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text(caption)
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var caption: String {
        if let selected {
            let unit = selected.stones == 1 ? "stone" : "stones"
            return "\(unit) · \(selected.label)"
        }
        let unit = total == 1 ? "stone" : "stones"
        return "\(unit) · \(period.caption)"
    }

    // MARK: Period picker (custom segmented control)

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(CoachInsights.TrendPeriod.allCases) { p in
                let active = p == period
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { period = p }
                } label: {
                    Text(p.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(active ? .white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(active ? Color.accentSage : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.bgTertiary.opacity(0.5))
        )
    }

    // MARK: Chart

    private var chart: some View {
        Chart(series) { point in
            BarMark(
                x: .value("Period", point.label),
                y: .value("Stones", point.stones)
            )
            .foregroundStyle(barColor(point))
            .cornerRadius(6)
        }
        .chartXSelection(value: $selectedLabel)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Color.textTertiary.opacity(0.15))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(height: 170)
    }

    private func barColor(_ point: CoachInsights.TrendPoint) -> Color {
        guard let selectedLabel else { return Color.accentSage }
        return point.label == selectedLabel ? Color.accentSage : Color.accentSage.opacity(0.30)
    }

    private var emptyNote: some View {
        Text("No stones in this window yet. Place one and it shows up here.")
            .font(.system(size: 13))
            .foregroundStyle(Color.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}
