import SwiftUI
import SwiftData

struct CoachView: View {
    @Query private var habits: [Habit]

    private var insights: CoachInsights { CoachInsights(habits: habits) }
    private var activeHabitCount: Int { habits.filter { !$0.isArchived }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                titleBlock
                guidanceCard

                if insights.comebackCount >= 1 {
                    comebackHero
                }

                if insights.lifetimeStones > 0 {
                    statGrid
                    CoachMomentumChart(insights: insights)
                }

                if insights.categoryBreakdown.count >= 2 {
                    categoryBreakdownSection
                }

                if let day = insights.bestWeekday { weekdayCard(day) }
                if let time = insights.bestTimeOfDay { timeOfDayCard(time) }

                habitHealthSection
                teachingTip
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

    // MARK: Today's read (the guide)

    private var guidanceCard: some View {
        let g = insights.todaysGuidance
        return VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow(g.eyebrow, trailing: "for you")
            HStack(alignment: .top, spacing: Spacing.sm) {
                iconBadge(g.icon)
                Text(g.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(g.body)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    // MARK: Comebacks — the heart of the shame-free promise

    private var comebackHero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionEyebrow("COMEBACKS", trailing: "all time")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(insights.comebackCount)")
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(Color.accentSage)
                Text(insights.comebackCount == 1 ? "return" : "returns")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.textPrimary)
            }
            Text("Every time you came back after a missed day. Most apps only count streaks — this is the number that actually matters.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    // MARK: Varied stat cards

    private struct Stat: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let caption: String
        let icon: String
    }

    private var stats: [Stat] {
        var out: [Stat] = []
        if insights.currentRunDays >= 2 {
            out.append(Stat(value: "\(insights.currentRunDays)", label: "CURRENT RUN",
                            caption: "days in a row", icon: "leaf.fill"))
        }
        if insights.weekStones > 0 {
            out.append(Stat(value: "\(insights.weekStones)", label: "THIS WEEK",
                            caption: insights.weekStones == 1 ? "stone placed" : "stones placed",
                            icon: "calendar"))
        }
        out.append(Stat(value: "\(insights.lifetimeStones)", label: "ALL TIME",
                        caption: insights.lifetimeStones == 1 ? "stone placed" : "stones placed",
                        icon: "circle.hexagongrid"))
        if insights.longestRunDays >= 3 {
            out.append(Stat(value: "\(insights.longestRunDays)", label: "BEST RUN",
                            caption: "days, your record", icon: "mountain.2"))
        }
        return out
    }

    private var statGrid: some View {
        let columns = [GridItem(.flexible(), spacing: Spacing.md),
                       GridItem(.flexible(), spacing: Spacing.md)]
        return LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(stats) { stat in
                statCard(stat)
            }
        }
    }

    private func statCard(_ stat: Stat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            iconBadge(stat.icon, size: 30)
            Text(stat.value)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text(stat.label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.accentSage)
            Text(stat.caption)
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(cardBackground)
    }

    // MARK: Category breakdown ("where your stones go")

    private var categoryBreakdownSection: some View {
        let items = insights.categoryBreakdown
        let maxStones = max(items.first?.stones ?? 1, 1)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow("WHERE YOUR STONES GO", trailing: "by area")
            VStack(spacing: Spacing.md) {
                ForEach(items) { item in
                    categoryRow(item, maxStones: maxStones)
                }
            }
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    private func categoryRow(_ item: CoachInsights.CategoryShare, maxStones: Int) -> some View {
        HStack(spacing: Spacing.sm) {
            iconBadge(item.iconName, size: 32)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(item.percent)%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentSage)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.accentSage.opacity(0.18))
                        Capsule().fill(Color.accentSage)
                            .frame(width: geo.size.width * CGFloat(item.stones) / CGFloat(maxStones))
                    }
                }
                .frame(height: 6)
            }
        }
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

    // MARK: Habit health (stone-dot sparklines)

    private var habitHealthSection: some View {
        let health = insights.habitHealth
        return VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow("HABIT HEALTH", trailing: "\(health.count) \(health.count == 1 ? "habit" : "habits")")

            if health.isEmpty {
                Text("Once a habit is a week old, its last two weeks show up here as a row of stones.")
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: Spacing.sm) {
                iconBadge(h.iconName, size: 32)
                Text(h.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text("\(h.completionPercent)%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(trendColor(h.trend))
            }
            dotTrail(h.dots, tint: trendColor(h.trend))
            Text(trendLabel(h.trend))
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(trendColor(h.trend))
        }
    }

    /// Last 14 days as small stones: filled = placed, faint = missed. A calm,
    /// non-judgmental alternative to a progress bar — gaps read as rest, not red.
    private func dotTrail(_ dots: [Bool], tint: Color) -> some View {
        HStack(spacing: 5) {
            ForEach(dots.indices, id: \.self) { i in
                Circle()
                    .fill(dots[i] ? tint : Color.bgTertiary)
                    .frame(width: 9, height: 9)
                    .frame(maxWidth: .infinity)
            }
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
        case .slipping:  return "READY FOR A GENTLER PLAN"
        }
    }

    // MARK: Teaching tip

    private var teachingTip: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionEyebrow("FROM THE COACH", trailing: "tip")
            Text(CoachMessages.dailyMessage(activeHabitCount: activeHabitCount))
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
