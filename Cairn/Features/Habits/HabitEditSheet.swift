import SwiftUI
import SwiftData

struct HabitEditSheet: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var vm: HabitEditViewModel
    @State private var showIconPicker = false

    init(habit: Habit) {
        self._habit = Bindable(habit)
        self._vm = State(initialValue: HabitEditViewModel(habit: habit))
    }

    var body: some View {
        NavigationStack {
            Form {
                iconRow
                nameSection
                categorySection
                ReminderSettingsView(
                    times: $vm.times,
                    schedule: $vm.schedule,
                    customDays: $vm.customDays
                )
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .navigationTitle("Edit habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { save() } label: { Text("Save").fontWeight(.semibold) }
                        .disabled(!vm.canSave)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerSheet(selected: $vm.iconName)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var iconRow: some View {
        Section {
            Button { showIconPicker = true } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: vm.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentSage)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentSage.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Icon")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text("Tap to change")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.vertical, Spacing.xs)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("Habit name", text: $vm.name).font(.system(size: 17))
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $vm.category) {
                ForEach(HabitCategory.allCases, id: \.self) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }
        }
    }

    private func save() {
        vm.apply(to: habit)
        do {
            try context.save()
            Task { @MainActor in
                if !vm.times.isEmpty {
                    await NotificationService.shared.ensureAuthorizedThenSchedule(habit)
                } else {
                    NotificationService.shared.cancel(habitId: habit.id)
                }
                dismiss()
            }
        } catch {
            print("❌ Edit save failed: \(error)")
        }
    }
}
