import SwiftUI

/// Bottom card shown when the user taps a day in the calendar. Has two parts:
///  - Top row: weekday/day chip on the left, "N stones placed" + habit names
///    in the middle, chevron on the right (visual only — no nav in v1.0)
///  - Bottom row: time pills, one per log on that day, with habit name
///    underneath
///
/// All data is precomputed by the parent — this view just renders.
struct GardenSelectedDayCard: View {
    let date: Date
    /// Habit name + log time, sorted by time ascending.
    let logs: [(habitName: String, loggedAt: Date)]

    var body: some View {
        VStack(spacing: 0) {
            topRow
            if !logs.isEmpty {
                Divider().overlay(Color.bgTertiary)
                timesRow
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Top row

    private var topRow: some View {
        HStack(spacing: Spacing.md) {
            // Date chip — MON / 23 stacked
            VStack(spacing: 2) {
                Text(weekdayShort.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.2)
                Text("\(dayNumber)")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentSage.opacity(0.20))
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(stonesPlacedLine)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                if !logs.isEmpty {
                    Text(habitNamesLine)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                } else {
                    Text("A gentle day.")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.md)
    }

    // MARK: Times row

    /// Horizontal scrollable row of time pills, one per log.
    private var timesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(Array(logs.enumerated()), id: \.offset) { _, log in
                    VStack(spacing: 4) {
                        Text(timeString(log.loggedAt))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.accentSage)
                        Text(log.habitName)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentSage.opacity(0.12))
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: Helpers

    private var weekdayShort: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private var stonesPlacedLine: String {
        switch logs.count {
        case 0: return "No stones placed"
        case 1: return "1 stone placed"
        default: return "\(logs.count) stones placed"
        }
    }

    /// "Meds · Water · Move · Wind down" — distinct habit names separated by
    /// midpoint. If too long, the lineLimit(2) handles wrapping.
    private var habitNamesLine: String {
        // Keep unique names in their first-occurrence order.
        var seen: Set<String> = []
        var names: [String] = []
        for log in logs {
            if !seen.contains(log.habitName) {
                seen.insert(log.habitName)
                names.append(log.habitName)
            }
        }
        return names.joined(separator: " · ")
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
