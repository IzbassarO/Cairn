import SwiftUI
import Charts

/// Interactive momentum chart for the Coach: one bar per day since day one,
/// growing as the account ages (a fresh account shows a single bar). Tap or
/// drag across the chart to read a specific day's count in the headline.
///
/// New file — auto-included via the project's file-system-synchronized groups.
struct CoachMomentumChart: View {
    let insights: CoachInsights

    @State private var selectedDate: Date?

    private var cal: Calendar { .current }
    private var series: [CoachInsights.TrendPoint] { insights.dailyMomentum() }
    private var total: Int { series.reduce(0) { $0 + $1.stones } }
    private var selected: CoachInsights.TrendPoint? {
        guard let selectedDate else { return nil }
        return series.first { cal.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            if total == 0 {
                emptyNote
            } else {
                chart
                Text("Tap or drag across the bars to read a day.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
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
            return "\(unit) · \(dayLabel(selected.date))"
        }
        let unit = total == 1 ? "stone" : "stones"
        return "\(unit) · since day one"
    }

    // MARK: Chart

    private var chart: some View {
        Chart(series) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Stones", point.stones)
            )
            .foregroundStyle(barColor(point))
            .cornerRadius(3)
        }
        .chartXSelection(value: $selectedDate)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine().foregroundStyle(Color.textTertiary.opacity(0.15))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(height: 170)
    }

    private func barColor(_ point: CoachInsights.TrendPoint) -> Color {
        guard let selectedDate else { return Color.accentSage }
        return cal.isDate(point.date, inSameDayAs: selectedDate)
            ? Color.accentSage
            : Color.accentSage.opacity(0.30)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private var emptyNote: some View {
        Text("No stones yet. Place one and it shows up here.")
            .font(.system(size: 13))
            .foregroundStyle(Color.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}
