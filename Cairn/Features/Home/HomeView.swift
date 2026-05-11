import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showCreation = false

    private var service: HabitService { HabitService(context: context) }
    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
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
                    if activeHabits.isEmpty {
                        emptyState
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.lg, trailing: Spacing.md))
                    } else {
                        ForEach(activeHabits) { habit in
                            HabitRow(habit: habit, onLog: { log(habit) })
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                        }
                        .onMove(perform: move)
                    }
                } header: {
                    if !activeHabits.isEmpty {
                        Text("Today")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                            .listRowInsets(EdgeInsets())
                            .textCase(nil)
                    }
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
            .task {
                await rescheduleNotificationsIfAuthorized()
            }
        }
        .tint(Color.accentSage)
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

    private var emptyState: some View {
        CairnCard {
            VStack(spacing: Spacing.md) {
                Text("Your cairn is empty.")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("Place your first stone when you're ready — no pressure, no streak.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    showCreation = true
                } label: {
                    Text("Pick a habit")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.accentSage))
                }
            }
            .frame(maxWidth: .infinity)
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
