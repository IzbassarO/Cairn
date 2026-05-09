import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showCreation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    greeting
                    cairnSection
                    habitsSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
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
        .tint(Color.accentSage)
    }

    private var greeting: some View {
        Text(greetingText)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.textPrimary)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Morning."
        case 12..<17: return "Afternoon."
        case 17..<22: return "Evening."
        default: return "Late night."
        }
    }

    private var cairnSection: some View {
        CairnCard {
            CairnView(stoneCount: totalLogs, daysActive: daysActive)
                .padding(.vertical, Spacing.md)
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            if habits.isEmpty {
                emptyState
            } else {
                ForEach(habits) { habit in
                    HabitRow(habit: habit, onLog: { log(habit) })
                }
            }
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

    private var totalLogs: Int {
        habits.reduce(0) { $0 + ($1.logs?.count ?? 0) }
    }

    private var daysActive: Int {
        let allDates = Set(habits.flatMap { ($0.logs ?? []).map { Calendar.current.startOfDay(for: $0.loggedAt) } })
        return allDates.count
    }

    private func log(_ habit: Habit) {
        do {
            let entry = HabitLog(habit: habit)
            context.insert(entry)
            try context.save()
            print("✅ Logged: \(habit.name)")
        } catch {
            print("❌ Log failed: \(error)")
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
                            Text("\(habit.logs?.count ?? 0) lifetime")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textTertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onLog) {
                    Image(systemName: loggedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(loggedToday ? Color.accentSage : Color.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(loggedToday ? "Logged today" : "Log \(habit.name)")
                .sensoryFeedback(.success, trigger: loggedToday)
            }
        }
    }

    private var loggedToday: Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return (habit.logs ?? []).contains { Calendar.current.startOfDay(for: $0.loggedAt) == today }
    }
}
