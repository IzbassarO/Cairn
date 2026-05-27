import SwiftUI
import SwiftData

struct CoachView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @Query(sort: \CoachMessage.createdAt, order: .reverse) private var coachMessages: [CoachMessage]

    @State private var inspected: InspectedHabit?
    @State private var editing: InspectedHabit?
    @State private var dismissedMove = false
    @State private var reflectionText = ""
    @FocusState private var reflectionFocused: Bool

    private var insights: CoachInsights { CoachInsights(habits: habits) }
    private var activeHabitCount: Int { habits.filter { !$0.isArchived }.count }
    private var reflections: [CoachMessage] { coachMessages.filter { $0.kind == .userComposed } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                titleBlock
                guidanceCard

                if let move = insights.oneSmallMove, !dismissedMove {
                    oneSmallMoveCard(move)
                }

                if insights.lifetimeStones > 0 {
                    statGrid
                }

                if let day = insights.bestWeekday { weekdayCard(day) }
                if let time = insights.bestTimeOfDay { timeOfDayCard(time) }

                habitFeelSection

                if let milestone = insights.milestoneReached {
                    milestoneCard(milestone)
                }

                if insights.comebackCount >= 1 {
                    comebackHero
                }

                reflectionCard

                if insights.categoryBreakdown.count >= 2 {
                    categoryBreakdownSection
                }

                teachingTip
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .fullScreenCover(item: $inspected) { item in
            HabitInfoView(habit: item.habit)
        }
        .fullScreenCover(item: $editing) { item in
            HabitEditView(habit: item.habit)
        }
    }

    // MARK: Title

    private var titleBlock: some View {
        let title = insights.coachTitle
        return VStack(alignment: .leading, spacing: 6) {
            Text("CAIRN COACH · WEEK \(insights.weekNumber)")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Color.accentSage)
            Text(title.line1)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text(title.line2)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.accentSage)
            Text(insights.weeklyNarrative)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
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
            HStack(alignment: .center, spacing: Spacing.sm) {
                StateStone(kind: .returning, size: 44)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(insights.comebackCount)")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(Color.accentSage)
                    Text(insights.comebackCount == 1 ? "return" : "returns")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.textPrimary)
                }
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

    // MARK: How your habits feel

    private var habitFeelSection: some View {
        let health = insights.habitHealth
        return VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                sectionEyebrow("HOW YOUR HABITS FEEL",
                               trailing: "\(health.count) \(health.count == 1 ? "habit" : "habits")")
                Text("A feel for each, this month.")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
            }

            if health.isEmpty {
                Text("Once a habit is a week old, how it's feeling shows up here.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
            } else {
                VStack(spacing: 10) {
                    ForEach(health) { h in
                        habitFeelRow(h)
                    }
                }
            }
        }
    }

    private func habitFeelRow(_ h: CoachInsights.HabitHealth) -> some View {
        Button {
            if let habit = habits.first(where: { $0.id == h.id }) {
                inspected = InspectedHabit(habit: habit)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                StateStone(kind: feelStone(h.feel), size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(h.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Text(h.feel.word)
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(feelColor(h.feel))
                    Text(h.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(cardBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func feelStone(_ f: CoachInsights.HabitFeel) -> StateStone.Kind {
        switch f {
        case .thriving:  return .thriving
        case .steady:    return .steady
        case .gentler:   return .slipping
        case .returning: return .returning
        }
    }

    private func feelColor(_ f: CoachInsights.HabitFeel) -> Color {
        switch f {
        case .thriving:  return .accentSage
        case .steady:    return .accentSage.opacity(0.75)
        case .gentler:   return .accentCoral
        case .returning: return .accentSage
        }
    }

    // MARK: Milestone

    private func milestoneCard(_ n: Int) -> some View {
        HStack(spacing: Spacing.md) {
            StateStone(kind: .milestone, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("MILESTONE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.accentSage)
                Text("\(n) stones placed — \(milestoneCaption(n)).")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func milestoneCaption(_ n: Int) -> String {
        switch n {
        case ..<50:   return "a small cairn"
        case ..<250:  return "a real cairn now"
        default:      return "a mountain of small wins"
        }
    }

    // MARK: One small move (dark, actionable card)

    private func oneSmallMoveCard(_ move: CoachInsights.SmallMove) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentSage)
                Text("ONE SMALL MOVE · GENTLE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color.accentSage)
            }
            Text(move.title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(move.body)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(move.ruleLine)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.45))

            HStack(spacing: Spacing.sm) {
                Button {
                    if let habit = habits.first(where: { $0.id == move.habitID }) {
                        editing = InspectedHabit(habit: habit)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3").font(.system(size: 13, weight: .bold))
                        Text("Adjust \(move.habitName)").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentSage))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeOut(duration: 0.25)) { dismissedMove = true }
                } label: {
                    Text("Not today")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgDark)
        )
    }

    // MARK: A small reflection (journaling)

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionEyebrow("A SMALL REFLECTION", trailing: "optional")
            Text(insights.reflectionPrompt)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                TextField(
                    "",
                    text: $reflectionText,
                    prompt: Text("Tap to write one sentence…").foregroundStyle(Color.textTertiary),
                    axis: .vertical
                )
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
                .focused($reflectionFocused)
                .lineLimit(1...4)

                if !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: saveReflection) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.accentSage)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        Color.textTertiary.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
            )

            if reflectionsThisMonth > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "leaf").font(.system(size: 12)).foregroundStyle(Color.accentSage)
                    Text("You've reflected \(reflectionsThisMonth) \(reflectionsThisMonth == 1 ? "time" : "times") this month — small notes add up.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.lg)
        .background(cardBackground)
    }

    private var reflectionsThisMonth: Int {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
        return reflections.filter { $0.createdAt >= start }.count
    }

    private func saveReflection() {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let msg = CoachMessage(kind: .userComposed, body: trimmed, modelUsed: "")
        context.insert(msg)
        do { try context.save() } catch { print("❌ Reflection save failed: \(error)") }
        withAnimation(.easeOut(duration: 0.2)) { reflectionText = "" }
        reflectionFocused = false
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
