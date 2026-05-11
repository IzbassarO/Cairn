import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    var body: some View {
        Group {
            if habit.modelContext != nil {
                content
            } else {
                Color.bgPrimary
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(habit.modelContext != nil ? habit.name : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if habit.modelContext != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit habit", systemImage: "pencil")
                        }
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
        }
        .cairnAlert(
            isPresented: $showDeleteConfirm,
            title: "Delete \(habit.modelContext != nil ? habit.name : "habit")?",
            message: "This habit and its logs will be removed. Your stones across the cairn stay with you.",
            icon: "trash.fill",
            confirmTitle: "Delete",
            confirmRole: .destructive,
            cancelTitle: "Keep it",
            onConfirm: { delete() }
        )
        .sheet(isPresented: $showEditSheet) {
            if habit.modelContext != nil {
                HabitEditSheet(habit: habit)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                stats
                heatmapSection
                recentLogs
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
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
            statCard(value: "\(habit.lifetimeStones)", label: "lifetime")
            statCard(value: "\(habit.uniqueLogDayCount)", label: "days")
            statCard(value: "\(habit.currentRun)", label: "current run")
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

    private var heatmapSection: some View {
        CairnCard {
            HeatmapView(logs: habit.logs ?? [])
                .padding(.vertical, Spacing.xs)
        }
    }

    private var recentLogs: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            let logs = (habit.logs ?? [])
                .filter { $0.modelContext != nil }
                .sorted { $0.loggedAt > $1.loggedAt }
                .prefix(10)

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

    private func delete() {
        let habitToDelete = habit
        let ctx = context
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let svc = HabitService(context: ctx)
            do {
                try svc.delete(habitToDelete)
                print("✅ Deleted habit")
            } catch {
                print("❌ Delete failed: \(error)")
            }
        }
    }
}
