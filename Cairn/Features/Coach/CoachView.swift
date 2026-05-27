import SwiftUI
import SwiftData

struct CoachView: View {
    @Query private var habits: [Habit]

    private var insights: CoachInsights { CoachInsights(habits: habits) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                titleBlock
                if insights.hasEnoughData {
                    if let day = insights.bestWeekday { weekdayCard(day) }
                    if let time = insights.bestTimeOfDay { timeOfDayCard(time) }
                    habitHealthSection
                } else {
                    warmupState
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CAIRN COACH")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Color.accentSage)
            Text("Patterns I've")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text("been watching.")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.accentSage)
            Text(insights.headline)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Weekday card ("THE READ")

    private func weekdayCard(_ day: CoachInsights.WeekdayInsight) -> some View {
        let maxCount = max(day.perWeekdayCounts.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow("THE READ", trailing: "this week")

            HStack(alignment: .top, spacing: Spacing.sm) {
                iconBadge("leaf")
                (Text("You're ").foregroundStyle(Color.textPrimary)
                 + Text("strongest").italic().foregroundStyle(Color.accentSage)
                 + Text(" on \(day.weekdaySymbol)s.").foregroundStyle(Color.textPrimary))
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("\(day.sharePercent)% of your stones land on \(day.weekdaySymbol)s. When you can, stack a new habit there — it's your hour.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Mini weekday bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(day.perWeekdayCounts.indices, id: \.self) { i in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(i == day.bestIndex ? Color.accentSage : Color.accentSage.opacity(0.22))
                            .frame(height: barHeight(day.perWeekdayCounts[i], max: maxCount))
                        Text(day.shortSymbols[i])
                            .font(.system(size: 11, weight: i == day.bestIndex ? .bold : .regular))
                            .foregroundStyle(i == day.bestIndex ? Color.accentSage : Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 88, alignment: .bottom)
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    private func barHeight(_ value: Int, max: Int) -> CGFloat {
        let minH: CGFloat = 6, maxH: CGFloat = 64
        guard max > 0 else { return minH }
        return minH + (maxH - minH) * CGFloat(value) / CGFloat(max)
    }

    // MARK: Time of day card

    private func timeOfDayCard(_ time: CoachInsights.TimeOfDayInsight) -> some View {
        let maxCount = max(time.hourBuckets.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow("WHEN YOU SHOW UP", trailing: "all time")

            (Text("\(time.label) are ").foregroundStyle(Color.textPrimary)
             + Text("your hour.").italic().foregroundStyle(Color.accentSage))
                .font(.system(size: 22, weight: .bold, design: .serif))

            Text("\(time.sharePercent)% of stones land \(time.detail). Lean into it.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // 24-hour mini chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<24, id: \.self) { h in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(h == time.peakHour ? Color.accentSage : Color.accentSage.opacity(0.22))
                        .frame(height: barHeight(time.hourBuckets[h], max: maxCount) * 0.7 + 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56, alignment: .bottom)

            HStack {
                Text("12a").font(.system(size: 10)).foregroundStyle(Color.textTertiary)
                Spacer()
                Text("noon").font(.system(size: 10)).foregroundStyle(Color.textTertiary)
                Spacer()
                Text("11p").font(.system(size: 10)).foregroundStyle(Color.textTertiary)
            }
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    // MARK: Habit health

    private var habitHealthSection: some View {
        let health = insights.habitHealth
        return VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow("HABIT HEALTH", trailing: "\(health.count) \(health.count == 1 ? "habit" : "habits")")

            if health.isEmpty {
                Text("Once your habits are a week old, their health shows up here.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(health) { h in
                        habitHealthRow(h)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    private func habitHealthRow(_ h: CoachInsights.HabitHealth) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: Spacing.sm) {
                iconBadge(h.iconName, size: 32)
                Text(h.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(h.completionPercent)%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(trendColor(h.trend))
            }
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.bgTertiary.opacity(0.5)).frame(height: 6)
                    Capsule().fill(trendColor(h.trend))
                        .frame(width: geo.size.width * CGFloat(h.completionPercent) / 100, height: 6)
                }
            }
            .frame(height: 6)
            Text(trendLabel(h.trend))
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(trendColor(h.trend))
        }
    }

    private func trendColor(_ t: CoachInsights.HealthTrend) -> Color {
        switch t {
        case .rockSolid: return .accentSage
        case .steady:    return .accentSage.opacity(0.7)
        case .slipping:  return .accentCoral
        }
    }

    private func trendLabel(_ t: CoachInsights.HealthTrend) -> String {
        switch t {
        case .rockSolid: return "ROCK SOLID"
        case .steady:    return "STEADY"
        case .slipping:  return "NEEDS A GENTLER PLAN"
        }
    }

    // MARK: Warmup (not enough data)

    private var warmupState: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                iconBadge("hourglass")
                Text("Still gathering your patterns.")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Coach reads your real history — no guesses. Place about \(insights.stonesUntilInsights) more \(insights.stonesUntilInsights == 1 ? "stone" : "stones") and your first patterns appear here.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Warmup progress
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.bgTertiary.opacity(0.5)).frame(height: 8)
                    Capsule().fill(Color.accentSage)
                        .frame(width: max(8, geo.size.width * insights.warmupProgress), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.top, 4)

            Text("Your patterns are private to your device. Coach never trains on you.")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
                .padding(.top, 4)
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    // MARK: Shared bits

    private func sectionEyebrow(_ leading: String, trailing: String) -> some View {
        HStack {
            Text(leading)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.accentSage)
            Spacer()
            Text(trailing)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func iconBadge(_ systemName: String, size: CGFloat = 40) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(Color.accentSage)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            .fill(Color.bgSecondary)
    }
}
