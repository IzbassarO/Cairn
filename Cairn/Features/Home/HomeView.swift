import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    /// Drives the post-plant orchestration. Set when F1 reports a saved habit;
    /// cleared after F5 closes. Owned here (not in TodayWelcomeView) because
    /// SwiftData makes `activeHabits` non-empty the moment the habit is saved
    /// and tears down the welcome view — taking any local state with it.
    @State private var celebration: PlantedHabitContext?

    /// True while the pre-permission overlay is on screen. Sits between the
    /// F1 dismissal and the iOS system alert.
    @State private var showingPrePermission = false

    /// Add-another flow trigger. Opens CustomHabitView (F7) fullScreen.
    /// In a later task, the N1 library will be added as a layer above this.
    @State private var showAddAnother = false

    /// When non-nil, the user tapped a habit row outside its circle and we
    /// open `HabitInfoView` for that habit. Cleared on dismiss.
    @State private var inspectedHabit: InspectedHabit?

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

            // Pre-permission overlay (F4). Lives above all content so it dims
            // everything underneath, including the just-dismissed F1.
            if showingPrePermission {
                PrePermissionView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            await rescheduleNotificationsIfAuthorized()
        }
        .fullScreenCover(isPresented: $showAddAnother) {
            AddAnotherHabitView { habit in
                // N1 (or its descendants N2/F7) saved a habit.
                // Dismiss the cover and schedule notifications. We don't run
                // the F4 pre-permission overlay here — that's reserved for
                // the very first habit. By this point the user has already
                // seen and resolved the iOS notification prompt.
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
                    // Open the add-another flow right after closing F5.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAddAnother = true
                    }
                }
            )
        }
        .fullScreenCover(item: $inspectedHabit) { inspected in
            HabitInfoView(habit: inspected.habit)
        }
    }

    // MARK: Returning user — Today scroll

    private var returningUserToday: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                TodayHeader()
                    .padding(.top, Spacing.sm)

                TodayCairnCard(
                    placedToday: placedTodayCount,
                    totalToday: activeHabits.count
                )

                habitsSectionHeader

                ForEach(activeHabits) { habit in
                    TodayHabitRow(
                        habit: habit,
                        onLog: { log(habit) },
                        onRowTap: { inspectedHabit = InspectedHabit(habit: habit) }
                    )
                }

                CoachCard(
                    message: CoachMessages.dailyMessage(
                        activeHabitCount: activeHabits.count
                    )
                )

                // Only encourage a second habit when the user has exactly one.
                // Beyond that, the section-header pill is the obvious entry.
                if activeHabits.count == 1 {
                    PlantSecondHabitCard {
                        showAddAnother = true
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: Section header (title + Add another)

    private var habitsSectionHeader: some View {
        HStack(alignment: .center) {
            Text(activeHabits.count == 1 ? "Your habit" : "Your habits")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            AddAnotherButton(
                style: activeHabits.count == 1 ? .ghost : .pill
            ) {
                showAddAnother = true
            }
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: Today progress

    /// Number of active habits that have at least one log today.
    private var placedTodayCount: Int {
        activeHabits.filter { $0.loggedToday }.count
    }

    // MARK: Logging

    private func log(_ habit: Habit) {
        // Idempotent for the same day — HabitService handles dedupe.
        do {
            try service.log(habit)
        } catch {
            print("❌ Log failed: \(error)")
        }
    }

    // MARK: Post-plant orchestration

    /// Runs after F1 dismisses. Decides whether to show the pre-permission
    /// overlay, when to trigger the iOS system alert, when to schedule
    /// notifications, and when to present F5.
    private func orchestratePostPlant(_ ctx: PlantedHabitContext) async {
        // Let F1 finish its dismissal animation before anything else moves.
        try? await Task.sleep(nanoseconds: 450_000_000)

        // If the user opted in to notifications and iOS hasn't yet asked
        // them, run the soft pre-prompt before the system alert.
        if ctx.notificationsOn {
            let authState = await NotificationService.shared.authorizationState()

            if authState == .notDetermined {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showingPrePermission = true
                }
                // Give the user time to read the card before the OS alert
                // pops over it. ~1.3s feels deliberate without being slow.
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

    // MARK: Notification rescheduling on launch

    private func rescheduleNotificationsIfAuthorized() async {
        let state = await NotificationService.shared.authorizationState()
        guard state == .authorized else { return }
        for habit in activeHabits {
            await NotificationService.shared.schedule(habit)
        }
    }
}

/// Identifiable wrapper around `Habit` so `fullScreenCover(item:)` can be used
/// without adding an Identifiable conformance to the SwiftData @Model.
struct InspectedHabit: Identifiable, Hashable {
    let id = UUID()
    let habit: Habit

    static func == (lhs: InspectedHabit, rhs: InspectedHabit) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
