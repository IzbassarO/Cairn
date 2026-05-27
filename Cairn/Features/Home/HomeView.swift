import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
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

    /// Pending undo confirm — removing a stone is destructive enough to confirm,
    /// so a mis-tap on a completed habit doesn't silently erase today's stone.
    @State private var pendingUndoHabit: InspectedHabit?

    /// Garden cover (View → calendar). Currently a stub; Part C builds it out.
    @State private var showGarden = false

    /// Today schedule cover (Day View timeline). Opened from the calendar
    /// icon in TodayHeader.
    @State private var showTodaySchedule = false

    /// Reminders inbox cover (last 30 days of reminders). Opened from the
    /// bell icon in TodayHeader.
    @State private var showRemindersInbox = false

    /// Filter for the habit list.
    @State private var selectedFilter: HabitFilter = .all

    /// Transient affirming message shown the moment a stone is placed.
    @State private var affirmation: String?
    /// Guards the auto-dismiss so rapid placements don't cut a message short.
    @State private var affirmationToken = 0

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

            if let affirmation {
                affirmationToast(affirmation)
            }
        }
        .task { await rescheduleNotificationsIfAuthorized() }
        .slideCover(isPresented: $showAddAnother) {
            AddAnotherHabitView(onClose: { showAddAnother = false }) { habit in
                showAddAnother = false
                Task {
                    if !habit.notificationTimes.isEmpty {
                        await NotificationService.shared.ensureAuthorizedThenSchedule(habit, settings: settings)
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
        .slideCover(isPresented: $showTodaySchedule) {
            TodayScheduleView(onClose: { showTodaySchedule = false })
        }
        .slideCover(isPresented: $showRemindersInbox) {
            RemindersInboxView(onClose: { showRemindersInbox = false })
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
        .cairnAlert(
            isPresented: pendingUndoBinding,
            title: "Remove this stone?",
            message: pendingUndoMessage,
            confirmTitle: "Remove",
            confirmRole: .destructive,
            cancelTitle: "Keep",
            onConfirm: { performUndo() }
        )
    }

    // MARK: Returning user — Today scroll

    private var returningUserToday: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TodayHeader(
                    onCalendarTap: { showTodaySchedule = true },
                    onBellTap: { showRemindersInbox = true }
                )
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
                        TodayHabitRow(
                            habit: habit,
                            onLog: { log(habit) },
                            onUndo: { pendingUndoHabit = InspectedHabit(habit: habit) },
                            onRowTap: { inspectedHabit = InspectedHabit(habit: habit) }
                        )
                        .contextMenu {
                            Button {
                                editingHabit = InspectedHabit(habit: habit)
                            } label: {
                                Label("Edit habit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                pendingDeleteHabit = InspectedHabit(habit: habit)
                            } label: {
                                Label("Delete habit", systemImage: "trash")
                            }
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

        // Persist inside the animation transaction so the @Query-driven removal
        // of the MoodSelector (todaysMood becomes non-nil) animates as a smooth
        // collapse rather than a hard cut.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
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
        }
    }

    // MARK: Logging

    private func log(_ habit: Habit) {
        // These all need the state BEFORE this placement.
        let stonesBefore = activeHabits.totalStones
        let wasFirstToday = !activeHabits.contains { $0.placedTodayCount > 0 }
        let comeback = isComeback(habit)

        do {
            let result = try service.log(habit)
            guard result == .logged else { return }  // at-cap taps: no feedback

            // Did this placement complete today's cairn?
            let everythingPlaced = !activeHabits.isEmpty
                && activeHabits.allSatisfy { $0.isFullyPlacedToday }

            // Did total stones cross a milestone (1, 10, 100, 250, 500, 1000)?
            let stonesAfter = stonesBefore + 1
            let milestones = [1, 10, 100, 250, 500, 1000]
            let hitMilestone = milestones.contains(stonesAfter)

            let haptic: HapticService.Feedback = hitMilestone ? .milestone
                : (everythingPlaced ? .dayComplete : .stonePlaced)
            HapticService.shared.play(haptic, enabled: settings.hapticFeedbackEnabled)

            // The "second moment": a brief affirming line. Priority runs from
            // the biggest event (milestone) down to an ordinary placement.
            let moment: CoachMessages.StoneMoment
            if hitMilestone { moment = .milestone(stonesAfter) }
            else if everythingPlaced { moment = .dayComplete }
            else if comeback { moment = .comeback }
            else if wasFirstToday { moment = .firstOfDay }
            else { moment = .placed }
            showAffirmation(CoachMessages.affirmation(for: moment))
        } catch {
            print("❌ Log failed: \(error)")
        }
    }

    /// True when this habit had prior momentum and is being placed after a
    /// 2+ day gap — i.e. the user is returning to it.
    private func isComeback(_ habit: Habit) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let priorDays = (habit.logs ?? [])
            .map { cal.startOfDay(for: $0.loggedAt) }
            .filter { $0 < today }
        guard let lastPrior = priorDays.max() else { return false }
        return (cal.dateComponents([.day], from: lastPrior, to: today).day ?? 0) >= 2
    }

    /// Show a transient affirmation, auto-dismissing after a beat. The token
    /// guards against an earlier dismissal cutting off a newer message.
    private func showAffirmation(_ text: String) {
        affirmationToken += 1
        let token = affirmationToken
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            affirmation = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if token == affirmationToken {
                withAnimation(.easeOut(duration: 0.3)) { affirmation = nil }
            }
        }
    }

    private func affirmationToast(_ text: String) -> some View {
        VStack {
            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.bgSecondary)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                )
                .padding(.top, Spacing.sm)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(2)
        .allowsHitTesting(false)
    }

    // MARK: Undo (confirm before removing a placed stone)

    private var pendingUndoBinding: Binding<Bool> {
        Binding(
            get: { pendingUndoHabit != nil },
            set: { if !$0 { pendingUndoHabit = nil } }
        )
    }

    private var pendingUndoMessage: String {
        guard let habit = pendingUndoHabit?.habit, habit.modelContext != nil else {
            return "Remove the stone you placed today? You can place it again anytime."
        }
        return "Remove the stone you placed for \u{201C}\(habit.name)\u{201D} today? You can place it again anytime."
    }

    /// Remove the most recent stone, after the user confirms.
    private func performUndo() {
        guard let habit = pendingUndoHabit?.habit else { return }
        pendingUndoHabit = nil
        do {
            if try service.removeLastStoneToday(habit) {
                HapticService.shared.play(.stonePlaced, enabled: settings.hapticFeedbackEnabled)
            }
        } catch {
            print("❌ Undo failed: \(error)")
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
            await NotificationService.shared.ensureAuthorizedThenSchedule(ctx.habit, settings: settings)
        }
        celebration = ctx
    }

    private func rescheduleNotificationsIfAuthorized() async {
        // Respects master switch + active pause via rescheduleAll.
        await NotificationService.shared.rescheduleAll(activeHabits, settings: settings)
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
