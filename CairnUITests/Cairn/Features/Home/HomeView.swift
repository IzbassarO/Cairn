import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    greeting
                    cairnVisualization
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
                    Button(action: addSampleHabit) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentSage)
                    }
                }
            }
        }
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

    private var cairnVisualization: some View {
        CairnCard {
            VStack(spacing: Spacing.sm) {
                Text("Your cairn")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
                Text("\(totalLogs) stones")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("placed across \(daysActive) days")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
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
            VStack(spacing: Spacing.sm) {
                Text("Your cairn is empty.")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text("Place your first stone when you're ready — no pressure, no streak.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }

    private var totalLogs: Int {
        habits.reduce(0) { $0 + $1.logs.count }
    }

    private var daysActive: Int {
        let allDates = Set(habits.flatMap { $0.logs.map { Calendar.current.startOfDay(for: $0.loggedAt) } })
        return allDates.count
    }

    private func log(_ habit: Habit) {
        let entry = HabitLog(habit: habit)
        context.insert(entry)
        try? context.save()
    }

    private func addSampleHabit() {
        let h = Habit(
            name: "Take meds",
            iconName: HabitCategory.meds.defaultIcon,
            category: .meds,
            sortOrder: habits.count
        )
        context.insert(h)
        try? context.save()
    }
}

struct HabitRow: View {
    let habit: Habit
    let onLog: () -> Void

    var body: some View {
        CairnCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: habit.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentSage)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("\(habit.logs.count) lifetime")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                }
                Spacer()
                Button(action: onLog) {
                    Image(systemName: loggedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(loggedToday ? Color.accentSage : Color.textTertiary)
                }
                .sensoryFeedback(.success, trigger: loggedToday)
            }
        }
    }

    private var loggedToday: Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return habit.logs.contains { Calendar.current.startOfDay(for: $0.loggedAt) == today }
    }
}
