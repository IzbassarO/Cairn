import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showCreation = false

    /// Drives the post-plant orchestration. Set when F1 reports a saved habit;
    /// cleared after F5 closes. Owned here (not in TodayWelcomeView) because
    /// SwiftData makes `activeHabits` non-empty the moment the habit is saved
    /// and tears down the welcome view — taking any local state with it.
    @State private var celebration: PlantedHabitContext?

    /// True while the pre-permission overlay is on screen. Sits between the
    /// F1 dismissal and the iOS system alert.
    @State private var showingPrePermission = false

    private var service: HabitService { HabitService(context: context) }
    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }

    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    if activeHabits.isEmpty {
                        // First-time entry: no nav bar, full custom layout.
                        TodayWelcomeView { ctx in
                            Task { await orchestratePostPlant(ctx) }
                        }
                        .navigationBarHidden(true)
                    } else {
                        returningUserList
                    }
                }
                .background(Color.bgPrimary)
                .task {
                    await rescheduleNotificationsIfAuthorized()
                }
            }
            .tint(Color.accentSage)

            // Pre-permission overlay (F4). Lives above the NavigationStack so
            // it dims everything underneath, including the just-dismissed F1.
            if showingPrePermission {
                PrePermissionView()
                    .transition(.opacity)
                    .zIndex(1)
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
                    // Placeholder per design — full-screen design will come later.
                    // For now just dismiss; the user lands on Today and can use
                    // the + in the toolbar to add another.
                    celebration = nil
                }
            )
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

                // Trigger the system alert. Whatever the user picks, the
                // service updates authorization state internally.
                _ = await NotificationService.shared.requestAuthorization()

                withAnimation(.easeOut(duration: 0.25)) {
                    showingPrePermission = false
                }
                // Brief settle so the overlay finishes fading before F5 covers.
                try? await Task.sleep(nanoseconds: 250_000_000)
            }

            // Schedule whatever we can. If permission was denied, this exits
            // cleanly without scheduling — the habit still exists, just silent.
            await NotificationService.shared.ensureAuthorizedThenSchedule(ctx.habit)
        }

        // F5.
        celebration = ctx
    }

    private var returningUserList: some View {
        List {
            Section {
                Text(Greeting.forCurrentHour())
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md))
            }

            Section {
                cairnSection
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: 0, trailing: Spacing.md))
            }

            Section {
                ForEach(activeHabits) { habit in
                    HabitRow(habit: habit, onLog: { log(habit) })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                }
                .onMove(perform: move)
            } header: {
                Text("Today")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .listRowInsets(EdgeInsets())
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentSage)
                }
                .accessibilityLabel("Add habit")
            }
        }
        .sheet(isPresented: $showCreation) {
            HabitCreationSheet()
        }
    }

    private var cairnSection: some View {
        CairnCard {
            CairnView(
                stoneCount: activeHabits.totalStones,
                daysActive: activeHabits.uniqueLogDayCount
            )
            .padding(.vertical, Spacing.md)
        }
    }

    private func log(_ habit: Habit) {
        do {
            try service.log(habit)
            print("✅ Logged: \(habit.name)")
        } catch {
            print("❌ Log failed: \(error)")
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)
        do {
            try service.reorder(reordered)
        } catch {
            print("❌ Reorder failed: \(error)")
        }
    }

    private func rescheduleNotificationsIfAuthorized() async {
        let state = await NotificationService.shared.authorizationState()
        guard state == .authorized else { return }
        for habit in activeHabits {
            await NotificationService.shared.schedule(habit)
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let onLog: () -> Void

    var body: some View {
        CairnCard {
            HStack(spacing: Spacing.md) {
                NavigationLink {
                    HabitDetailView(habit: habit)
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.accentSage)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text("\(habit.lifetimeStones) lifetime")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textTertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onLog) {
                    Image(systemName: habit.loggedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(habit.loggedToday ? Color.accentSage : Color.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(habit.loggedToday ? "Logged today" : "Log \(habit.name)")
                .sensoryFeedback(.success, trigger: habit.loggedToday)
            }
        }
    }
}
