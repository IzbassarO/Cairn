import SwiftUI
import SwiftData

struct HabitCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @State private var vm = HabitCreationViewModel()

    private var service: HabitService { HabitService(context: context) }

    var body: some View {
        NavigationStack {
            Group {
                if vm.selectedTemplate != nil {
                    customizeView
                } else {
                    templateGrid
                }
            }
            .background(Color.bgPrimary)
        }
    }

    private var templateGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Pick something tiny.")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text("ADHD brains do better with one habit at a time. Start small. You can always add more.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.md),
                        GridItem(.flexible(), spacing: Spacing.md)
                    ],
                    spacing: Spacing.md
                ) {
                    ForEach(HabitTemplates.all) { template in
                        Button {
                            vm.selectTemplate(template)
                        } label: {
                            templateCard(template)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .navigationTitle("New habit")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func templateCard(_ t: HabitTemplate) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: t.iconName)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.accentSage)
            Text(t.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.leading)
            Text(t.blurb)
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    @ViewBuilder
    private var customizeView: some View {
        if let template = vm.selectedTemplate {
            Form {
                Section {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: template.iconName)
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentSage)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.accentSage.opacity(0.15)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.category.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                                .textCase(.uppercase)
                            Text(template.blurb)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section("Name") {
                    TextField("Habit name", text: $vm.customName)
                        .font(.system(size: 17))
                }

                Section {
                    ReminderSettingsView(
                        times: $vm.times,
                        schedule: $vm.schedule,
                        customDays: $vm.customDays
                    )
                }
            }
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { vm.clearTemplate() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        submit()
                    } label: {
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .disabled(!vm.canSubmit)
                }
            }
        }
    }

    private func submit() {
        guard let habit = vm.buildHabit(sortOrder: habits.count) else { return }
        do {
            try service.add(habit)
            print("✅ Added habit: \(habit.name)")

            if !vm.times.isEmpty {
                Task { @MainActor in
                    await NotificationService.shared.ensureAuthorizedThenSchedule(habit)
                }
            }
            dismiss()
        } catch {
            vm.errorMessage = "\(error)"
            print("❌ Add habit failed: \(error)")
        }
    }
}
