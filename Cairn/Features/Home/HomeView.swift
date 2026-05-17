import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var moodLogs: [MoodLog]

    /// First-habit celebration (F5). Owned here, set after F1 plants the first habit.
    @State private var celebration: PlantedHabitContext?
    @State private var showingPrePermission = false

    /// Add-another flow (opens N1 library).
    @State private var showAddAnother = false

    /// Tapped row → opens HabitInfoView.
    @State private var inspectedHabit: InspectedHabit?

    /// Edit-from-swipe.
    @State private var editingHabit: InspectedHabit?

    /// Pending delete confirm (swipe Delete or full-swipe).
    @State private var pendingDeleteHabit: InspectedHabit?

    /// Garden cover (View → calendar). Currently a stub; Part C builds it out.
    @State private var showGarden = false

    /// Filter for the habit list.
    @State private var selectedFilter: HabitFilter = .all

    private var service: HabitService { HabitService(context: context) }
    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if activeHabits.isEmpty {
                TodayWelcomeView { ctx in
                    Task { await orchestratePostPlant(ctx) }
                }
            } else {
                returningUserToday
            }

            if showingPrePermission {
                PrePermissionView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task { await rescheduleNotificationsIfAuthorized() }
        .fullScreenCover(isPresented: $showAddAnother) {
            AddAnotherHabitView { habit in
                showAddAnother = false
                Task {
                    if !habit.notificationTimes.isEmpty {
                        await NotificationService.shared.ensureAuthorizedThenSchedule(habit)
                    }
                }
            }
        }
        .fullScreenCover(item: $celebration) { ctx in
            FirstHabitPlantedView(
                habitName: ctx.habitName,
                timeLabel: ctx.timeLabel,
                daysLabel: ctx.daysLabel,
                notificationsOn: ctx.notificationsOn,
                onSeeToday: { celebration = nil },
                onPlantAnother: {
                    celebration = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAddAnother = true
                    }
                }
            )
        }
        .fullScreenCover(item: $inspectedHabit) { inspected in
            HabitInfoView(habit: inspected.habit)
        }
        .fullScreenCover(item: $editingHabit) { editing in
            HabitEditView(habit: editing.habit)
        }
        .fullScreenCover(isPresented: $showGarden) {
            GardenView()
        }
        .cairnAlert(
            isPresented: pendingDeleteBinding,
            title: "Delete this habit?",
            message: pendingDeleteMessage,
            confirmTitle: "Delete",
            confirmRole: .destructive,
            cancelTitle: "Cancel",
            onConfirm: { performSwipeDelete() }
        )
    }

    // MARK: Returning user — Today scroll

    private var returningUserToday: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TodayHeader()
                    .padding(.top, Spacing.sm)

                StonesWidget(
                    placedHabits: placedHabitsToday,
                    totalScheduledToday: activeHabits.count
                )

                TodayCairnCard(
                    placedToday: placedHabitsToday.count,
                    totalToday: activeHabits.count,
                    nextUpAt: nextReminderAt,
                    last7DaysCounts: last7DaysCounts,
                    last7DaysTotal: last7DaysCounts.reduce(0, +),
                    usualDailyAverage: usualDailyAverage,
                    onViewGarden: { showGarden = true }
                )

                if let upNext = upNextHabit, let time = nextReminderAt {
                    UpNextCard(habit: upNext, reminderTime: time)
                }

                if todaysMood == nil {
                    MoodSelector(selected: nil) { mood in
                        recordMood(mood)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                habitsSectionHeader

                HabitFilterChips(
                    selected: $selectedFilter,
                    allCount: activeHabits.count,
                    pendingCount: pendingHabitsToday.count,
                    doneCount: placedHabitsToday.count
                )
                .padding(.top, 2)

                habitsList

                // Only encourage a second habit when the user has exactly one.
                if activeHabits.count == 1 {
                    PlantSecondHabitCard {
                        showAddAnother = true
                    }
                    .padding(.top, Spacing.sm)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: Section header

    private var habitsSectionHeader: some View {
        HStack(alignment: .center) {
            Text(activeHabits.count == 1 ? "Your habit" : "Your habits")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            AddAnotherButton(style: .pill) {
                showAddAnother = true
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: Habits list (grouped by category)

    @ViewBuilder
    private var habitsList: some View {
        let groups = groupedHabits()
        if groups.isEmpty {
            emptyFilteredState
        } else {
            ForEach(groups, id: \.category) { group in
                if shouldShowCategoryHeader {
                    HabitsCategoryHeader(
                        category: group.category,
                        placedCount: group.habits.filter { $0.isFullyPlacedToday }.count,
                        totalCount: group.habits.count
                    )
                }
                VStack(spacing: 8) {
                    ForEach(group.habits) { habit in
                        SwipeableRow(
                            actions: [
                                SwipeAction(
                                    title: "Edit",
                                    icon: "pencil",
                                    tint: Color.accentSage,
                                    action: { editingHabit = InspectedHabit(habit: habit) }
                                ),
                                SwipeAction(
                                    title: "Delete",
                                    icon: "trash",
                                    tint: Color.accentCoral,
                                    action: { pendingDeleteHabit = InspectedHabit(habit: habit) }
                                )
                            ],
                            onFullSwipe: { pendingDeleteHabit = InspectedHabit(habit: habit) }
                        ) {
                            TodayHabitRow(
                                habit: habit,
                                onLog: { log(habit) },
                                onRowTap: { inspectedHabit = InspectedHabit(habit: habit) }
                            )
                        }
                    }
                }
            }
        }
    }

    /// Only show category headers when there are at least two distinct
    /// categories represented. A single-category list reads better flat.
    private var shouldShowCategoryHeader: Bool {
        Set(filteredHabits.map(\.category)).count > 1
    }

    private var emptyFilteredState: some View {
        VStack(spacing: 6) {
            Text(emptyFilterMessage)
                .font(.system(size: 15, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private var emptyFilterMessage: String {
        switch selectedFilter {
        case .all: return "No habits yet."
        case .pending: return "Everything for today is done. ✓"
        case .done: return "Nothing placed yet today."
        }
    }

    // MARK: Derived — filtering & grouping

    private var placedHabitsToday: [Habit] {
        activeHabits.filter { $0.isFullyPlacedToday }
    }

    private var pendingHabitsToday: [Habit] {
        activeHabits.filter { !$0.isFullyPlacedToday }
    }

    private var filteredHabits: [Habit] {
        switch selectedFilter {
        case .all: return activeHabits
        case .pending: return pendingHabitsToday
        case .done: return placedHabitsToday
        }
    }

    private struct HabitGroup {
        let category: HabitCategory
        let habits: [Habit]
    }

    private func groupedHabits() -> [HabitGroup] {
        let buckets = Dictionary(grouping: filteredHabits) { $0.category }
        // Stable category order from HabitCategory.allCases.
        return HabitCategory.allCases.compactMap { cat in
            guard let list = buckets[cat], !list.isEmpty else { return nil }
            return HabitGroup(category: cat, habits: list.sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    // MARK: Derived — next reminder

    /// Next unplaced habit whose reminder time is later today, soonest first.
    /// Drives both the Today's Cairn "next up at HH:MM" subline and the
    /// UpNextCard.
    private var upNextHabit: Habit? {
        let now = Date.now
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)
        let todayEnd = cal.date(byAdding: .day, value: 1, to: todayStart) ?? now

        // For each unplaced habit, project its reminder time onto today.
        let candidates: [(habit: Habit, when: Date)] = pendingHabitsToday.compactMap { habit in
            guard let raw = habit.notificationTimes.first else { return nil }
            let comps = cal.dateComponents([.hour, .minute], from: raw)
            guard let projected = cal.date(bySettingHour: comps.hour ?? 0,
                                           minute: comps.minute ?? 0,
                                           second: 0, of: now) else { return nil }
            guard projected >= now && projected < todayEnd else { return nil }
            return (habit, projected)
        }
        return candidates.min { $0.when < $1.when }?.habit
    }

    private var nextReminderAt: Date? {
        guard let habit = upNextHabit, let raw = habit.notificationTimes.first else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: raw)
        return cal.date(bySettingHour: comps.hour ?? 0,
                        minute: comps.minute ?? 0,
                        second: 0, of: .now)
    }

    // MARK: Derived — last 7 days

    /// Counts of unique habits placed per day for the last 7 days, oldest first.
    /// "Unique habits" because multi-target habits log multiple times per day.
    private var last7DaysCounts: [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var counts: [Int] = []
        for i in (0..<7).reversed() {
            guard let day = cal.date(byAdding: .day, value: -i, to: today) else {
                counts.append(0); continue
            }
            let placedThatDay: Int = activeHabits.reduce(0) { acc, habit in
                let any = (habit.logs ?? []).contains {
                    cal.isDate($0.loggedAt, inSameDayAs: day)
                }
                return acc + (any ? 1 : 0)
            }
            counts.append(placedThatDay)
        }
        return counts
    }

    /// Long-term average daily stones across the user's history. Excludes
    /// the last 7 days (so the comparison isn't comparing to itself).
    private var usualDailyAverage: Double? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let last7Start = cal.date(byAdding: .day, value: -6, to: today) ?? today
        // Look at the prior 30 days before that window.
        let baselineEnd = cal.date(byAdding: .day, value: -1, to: last7Start) ?? today
        let baselineStart = cal.date(byAdding: .day, value: -30, to: baselineEnd) ?? today

        var totalPlaced = 0
        var days = 0
        var cursor = baselineStart
        while cursor <= baselineEnd {
            let placed = activeHabits.reduce(0) { acc, habit in
                let any = (habit.logs ?? []).contains {
                    cal.isDate($0.loggedAt, inSameDayAs: cursor)
                }
                return acc + (any ? 1 : 0)
            }
            totalPlaced += placed
            days += 1
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86400)
        }
        guard days >= 7 else { return nil } // not enough history for a baseline
        return Double(totalPlaced) / Double(days)
    }

    // MARK: Mood

    /// Today's mood log, if one exists.
    private var todaysMood: MoodLog? {
        let cal = Calendar.current
        return moodLogs.first { cal.isDate($0.day, inSameDayAs: .now) }
    }

    /// Persist mood. We dedupe — one MoodLog per day, replacing any existing
    /// entry (covers the edge case of changing mood within the same day).
    /// Animation of the MoodSelector disappearing is driven by `todaysMood`
    /// becoming non-nil after we save.
    private func recordMood(_ mood: MoodValue) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: .now)

        if let existing = todaysMood {
            existing.mood = mood
            existing.loggedAt = .now
        } else {
            let log = MoodLog(day: dayStart, mood: mood, loggedAt: .now)
            context.insert(log)
        }
        do {
            try context.save()
        } catch {
            print("❌ MoodLog save failed: \(error)")
        }
        withAnimation(.easeOut(duration: 0.35)) {
            // todaysMood becomes non-nil → MoodSelector branch goes away.
        }
    }

    // MARK: Logging

    private func log(_ habit: Habit) {
        do {
            try service.log(habit)
        } catch {
            print("❌ Log failed: \(error)")
        }
    }

    // MARK: Post-plant orchestration

    private func orchestratePostPlant(_ ctx: PlantedHabitContext) async {
        try? await Task.sleep(nanoseconds: 450_000_000)
        if ctx.notificationsOn {
            let authState = await NotificationService.shared.authorizationState()
            if authState == .notDetermined {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showingPrePermission = true
                }
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                _ = await NotificationService.shared.requestAuthorization()
                withAnimation(.easeOut(duration: 0.25)) {
                    showingPrePermission = false
                }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            await NotificationService.shared.ensureAuthorizedThenSchedule(ctx.habit)
        }
        celebration = ctx
    }

    private func rescheduleNotificationsIfAuthorized() async {
        let state = await NotificationService.shared.authorizationState()
        guard state == .authorized else { return }
        for habit in activeHabits {
            await NotificationService.shared.schedule(habit)
        }
    }

    // MARK: Swipe-delete helpers

    private var pendingDeleteBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteHabit != nil },
            set: { newValue in
                if !newValue { pendingDeleteHabit = nil }
            }
        )
    }

    private var pendingDeleteMessage: String {
        guard let inspected = pendingDeleteHabit,
              inspected.habit.modelContext != nil
        else {
            return "This habit will be removed. This can't be undone."
        }
        let habit = inspected.habit
        let stones = (habit.logs ?? []).filter { $0.modelContext != nil }.count
        switch stones {
        case 0: return "\u{201C}\(habit.name)\u{201D} will be removed. This can't be undone."
        case 1: return "\u{201C}\(habit.name)\u{201D} and its 1 stone will be removed. This can't be undone."
        default: return "\u{201C}\(habit.name)\u{201D} and its \(stones) stones will be removed. This can't be undone."
        }
    }

    private func performSwipeDelete() {
        guard let inspected = pendingDeleteHabit else { return }
        let habitRef = inspected.habit
        pendingDeleteHabit = nil
        let svc = HabitService(context: context)
        do {
            try svc.delete(habitRef)
        } catch {
            print("❌ Swipe delete failed: \(error)")
        }
    }
}

/// Identifiable wrapper around `Habit` so `fullScreenCover(item:)` can be used
/// without adding an Identifiable conformance to the SwiftData @Model.
struct InspectedHabit: Identifiable, Hashable {
    let id = UUID()
    let habit: Habit

    static func == (lhs: InspectedHabit, rhs: InspectedHabit) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
