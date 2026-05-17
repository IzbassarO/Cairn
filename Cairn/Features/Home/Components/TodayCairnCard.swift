import SwiftUI

/// Big Today card from mockup T. Two halves separated by a hairline:
///  - **Top**: today's progress (placed + remaining, dashed bar, ring on right)
///  - **Bottom**: last 7 days bar chart with "View" button → Garden
///
/// All copy adapts: resting state (0 placed), in-progress, all done.
struct TodayCairnCard: View {
    let placedToday: Int
    let totalToday: Int
    /// `Date?` of the next reminder among unplaced habits, used for the
    /// "next up at HH:MM" subline. Nil → "all set for today" / empty.
    let nextUpAt: Date?
    /// Per-day counts for the last 7 days, oldest first. Each int is the
    /// number of habits the user logged that day.
    let last7DaysCounts: [Int]
    /// Total stones across last 7 days.
    let last7DaysTotal: Int
    /// User's average daily count over a longer window — used to compute the
    /// "+18% above usual" pill. Pass nil to hide the comparison.
    let usualDailyAverage: Double?

    /// Opens the Garden full-screen. Wired by HomeView.
    let onViewGarden: () -> Void

    // Derived
    private var isResting: Bool { placedToday == 0 }
    private var isComplete: Bool { placedToday >= totalToday && totalToday > 0 }
    private var remaining: Int { max(0, totalToday - placedToday) }
    private var fraction: Double {
        totalToday > 0 ? min(1, Double(placedToday) / Double(totalToday)) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            topHalf
            Divider().overlay(Color.bgTertiary)
            bottomHalf
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Top half

    private var topHalf: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY'S CAIRN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                copyLine
                progressDashes
                subline
            }
            Spacer(minLength: Spacing.sm)
            progressRing
        }
        .padding(.bottom, Spacing.md)
    }

    @ViewBuilder
    private var copyLine: some View {
        if isResting {
            HStack(spacing: 4) {
                Text("\(totalToday) stones")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("waiting.")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
        } else if isComplete {
            HStack(spacing: 4) {
                Text("\(placedToday) placed.")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("Beautiful.")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
        } else {
            HStack(spacing: 4) {
                Text("\(placedToday) stones placed,")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text(remaining == 1 ? "1 to go." : "\(remaining) to go.")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
        }
    }

    /// Dashed progress bar — one capsule per habit. Filled capsules are sage,
    /// remaining are sage opacity-20.
    private var progressDashes: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(totalToday, 1), id: \.self) { i in
                Capsule()
                    .fill(i < placedToday ? Color.accentSage : Color.accentSage.opacity(0.20))
                    .frame(height: 6)
            }
        }
    }

    @ViewBuilder
    private var subline: some View {
        if isComplete {
            Text("Every stone is placed.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        } else if let nextUp = nextUpAt {
            HStack(spacing: 4) {
                Text("\(Int(fraction * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Text("· next up at")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
                Text(timeString(nextUp))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
        } else if isResting {
            Text("Take the first one whenever you're ready.")
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(Color.textTertiary)
        } else {
            Text("\(Int(fraction * 100))% of today's cairn placed.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    // MARK: Progress ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.accentSage.opacity(0.20), lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(
                    Color.accentSage,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.55, dampingFraction: 0.78), value: fraction)
            VStack(spacing: 0) {
                Text("\(placedToday)/\(totalToday)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("STONES")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.2)
            }
        }
        .frame(width: 78, height: 78)
    }

    // MARK: Bottom half — Last 7 Days

    private var bottomHalf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("LAST 7 DAYS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(1.4)
                Spacer()
                last7DaysBadge
            }
            barsRow
            Button(action: onViewGarden) {
                HStack(spacing: 4) {
                    Text("View Garden")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.accentSage)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, Spacing.md)
    }

    /// Right-aligned info pill — total stones + comparison to usual average.
    @ViewBuilder
    private var last7DaysBadge: some View {
        HStack(spacing: 4) {
            Text("\(last7DaysTotal) stones")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            if let comparison = comparisonText {
                Text("·")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                Text(comparison)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
            }
        }
    }

    /// "+18% above usual" or "−12% below usual". Returns nil for the first
    /// few days when we have no baseline.
    private var comparisonText: String? {
        guard let usual = usualDailyAverage, usual > 0, last7DaysTotal > 0 else { return nil }
        let observed = Double(last7DaysTotal) / 7.0
        let pct = ((observed - usual) / usual) * 100
        guard abs(pct) >= 5 else { return nil }
        let rounded = Int(abs(pct).rounded())
        return pct > 0 ? "+\(rounded)% above usual" : "−\(rounded)% below usual"
    }

    /// 7 vertical bars, one per day. Today is the rightmost and renders dark
    /// (charcoal) regardless of count — clearly "you are here".
    private var barsRow: some View {
        let maxCount = (last7DaysCounts.max() ?? 0)
        return VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(last7DaysCounts.enumerated()), id: \.offset) { idx, count in
                    let isToday = idx == last7DaysCounts.count - 1
                    barCell(count: count, maxCount: maxCount, isToday: isToday)
                }
            }
            .frame(height: 40)
            // Day-of-week labels (M T W ...) — derive from today going backwards.
            HStack(spacing: 6) {
                ForEach(Array(weekdayLabels().enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func barCell(count: Int, maxCount: Int, isToday: Bool) -> some View {
        // Compute the height fraction. We use `Swift.max(...)` explicitly so
        // it can't be confused with the `maxCount` parameter.
        let fraction: CGFloat
        if maxCount == 0 {
            fraction = 0
        } else {
            // Floor so empty days are still visible as a faint stub.
            fraction = Swift.max(CGFloat(count) / CGFloat(maxCount), 0.15)
        }
        let fill: Color = isToday
            ? Color.textPrimary
            : (count == 0 ? Color.accentSage.opacity(0.25) : Color.accentSage)
        return GeometryReader { geo in
            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(fill)
                    .frame(height: Swift.max(geo.size.height * fraction, 6))
            }
        }
    }

    /// Returns the seven weekday initials ending with today. e.g. if today is
    /// Thursday → ["F","S","S","M","T","W","T"].
    private func weekdayLabels() -> [String] {
        let cal = Calendar.current
        let initials = ["S", "M", "T", "W", "T", "F", "S"] // 1=Sun (rawValue from cal)
        let today = cal.component(.weekday, from: .now) // 1=Sun ... 7=Sat
        var result: [String] = []
        for i in (0..<7).reversed() {
            let idx = ((today - 1 - i) % 7 + 7) % 7
            result.append(initials[idx])
        }
        return result
    }
}
