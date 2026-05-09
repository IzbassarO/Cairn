import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                stats
                recentLogs
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.bgPrimary)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete habit", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.accentSage)
                }
            }
        }
        .confirmationDialog(
            "Delete \(habit.name)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteHabit() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This habit and its logs will be removed. Your overall stones stay with you.")
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: habit.iconName)
                .font(.system(size: 28))
                .foregroundStyle(Color.accentSage)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentSage.opacity(0.15)))
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(habit.category.displayName)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
        }
    }

    private var stats: some View {
        HStack(spacing: Spacing.md) {
            statCard(value: "\(habit.logs?.count ?? 0)", label: "lifetime")
            statCard(value: "\(uniqueDays)", label: "days")
            statCard(value: "\(currentRun)", label: "current run")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        CairnCard(padding: Spacing.md) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var recentLogs: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            let logs = (habit.logs ?? []).sorted { $0.loggedAt > $1.loggedAt }.prefix(20)
            if logs.isEmpty {
                CairnCard {
                    Text("No logs yet. The first stone is the heaviest.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(Array(logs), id: \.id) { log in
                    CairnCard(padding: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentSage)
                            Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 14))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var uniqueDays: Int {
        let cal = Calendar.current
        return Set((habit.logs ?? []).map { cal.startOfDay(for: $0.loggedAt) }).count
    }

    private var currentRun: Int {
        StreakCalculator().currentRun(habit.logs ?? [])
    }

    private func deleteHabit() {
        context.delete(habit)
        do {
            try context.save()
            dismiss()
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }
}
