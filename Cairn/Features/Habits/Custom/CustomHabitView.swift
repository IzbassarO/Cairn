import SwiftUI
import SwiftData

struct CustomHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// Called when the user successfully saves. The presenter (HomeView or
    /// TodayWelcomeView) decides what to do next — orchestrate F4/F5 for the
    /// first habit, or just dismiss for subsequent ones.
    let onPlanted: (Habit) -> Void

    @State private var draft = CustomHabitDraft()
    @State private var showIconPicker = false
    @State private var showTimeSheet = false
    @State private var showDaysSheet = false
    /// Which slot of `reminderTimes` is being edited. Used only when target > 1.
    @State private var editingTimeIndex: Int = 0

    private var service: HabitService { HabitService(context: context) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    iconPickerTrigger
                    nameField
                    scheduleCard
                    cueNoteSection
                    helperHint
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(selected: $draft.iconName)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showTimeSheet) {
            // The time sheet edits a single slot. For target == 1 the slot
            // is always index 0; for target > 1 the row that was tapped sets
            // `editingTimeIndex` first.
            SingleTimeEditorSheet(
                time: bindingForEditingTime(),
                slotIndex: editingTimeIndex,
                totalSlots: draft.reminderTimes.count
            )
        }
        .sheet(isPresented: $showDaysSheet) {
            CustomDaysSheet(draft: draft)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.bgSecondary))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .accessibilityLabel("Cancel")

            Spacer()

            Text("Custom habit")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                Task { await save() }
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(draft.canSave ? Color.accentSage : Color.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            draft.canSave
                                ? Color.accentSage.opacity(0.15)
                                : Color.bgSecondary
                        )
                    )
            }
            .disabled(!draft.canSave)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Icon picker

    private var iconPickerTrigger: some View {
        VStack(spacing: 8) {
            Button {
                showIconPicker = true
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            Color.accentSage.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                        .background(
                            Circle().fill(Color.bgSecondary)
                        )
                    Image(systemName: draft.iconName)
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(Color.accentSage)
                }
                .frame(width: 96, height: 96)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose an icon")

            Text("TAP TO CHOOSE AN ICON")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }

    // MARK: Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("NAME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            TextField("", text: $draft.name, prompt:
                Text("What are you tending?")
                    .font(.system(size: 18, design: .serif))
                    .italic()
                    .foregroundStyle(Color.textTertiary)
            )
            .font(.system(size: 18, design: .serif))
            .italic()
            .foregroundStyle(Color.textPrimary)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(false)
            .padding(.vertical, 16)
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )

            Text("e.g. \"Drink water\", \"Walk after lunch\", \"Read 5 pages\"")
                .font(.system(size: 12, design: .serif))
                .italic()
                .foregroundStyle(Color.textTertiary)
                .padding(.leading, Spacing.xs)
        }
    }

    // MARK: Schedule card

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SCHEDULE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                // For target == 1 we show a single Reminder row.
                // For target > 1 we show N rows, one per slot.
                if draft.targetPerDay == 1 {
                    reminderRow(slot: 0, label: "REMINDER TIME")
                } else {
                    ForEach(0..<draft.reminderTimes.count, id: \.self) { idx in
                        reminderRow(slot: idx, label: "REMINDER \(idx + 1)")
                        if idx < draft.reminderTimes.count - 1 {
                            divider
                        }
                    }
                }

                divider

                daysRow

                divider

                notificationToggleRow

                divider

                timesPerDayRow
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private var divider: some View {
        Divider().overlay(Color.bgTertiary).padding(.leading, 72)
    }

    private func reminderRow(slot: Int, label: String) -> some View {
        let disabled = !draft.notificationsEnabled
        let valueText = formatTime(draft.reminderTimes[safe: slot] ?? .now)
        return Button {
            editingTimeIndex = slot
            showTimeSheet = true
        } label: {
            HStack(spacing: Spacing.md) {
                iconTile(systemName: "clock")
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .tracking(1.4)
                    Text(valueText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(disabled ? Color.textTertiary : Color.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1.0)
    }

    private var daysRow: some View {
        Button {
            showDaysSheet = true
        } label: {
            HStack(spacing: Spacing.md) {
                iconTile(systemName: "calendar")
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAYS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .tracking(1.4)
                    Text(draft.daysSummary)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var notificationToggleRow: some View {
        HStack(spacing: Spacing.md) {
            iconTile(systemName: "bell")
            VStack(alignment: .leading, spacing: 2) {
                Text("LOCAL NOTIFICATION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(1.4)
                Text("A gentle nudge — never twice.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: $draft.notificationsEnabled)
                .labelsHidden()
                .tint(Color.accentSage)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }

    private var timesPerDayRow: some View {
        HStack(spacing: Spacing.md) {
            iconTile(systemName: "repeat")
            VStack(alignment: .leading, spacing: 2) {
                Text("TIMES PER DAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(1.4)
                Text(draft.targetPerDay == 1
                    ? "Once"
                    : "\(draft.targetPerDay) times")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Stepper("", value: Binding(
                get: { draft.targetPerDay },
                set: { newValue in
                    draft.targetPerDay = newValue
                    draft.syncReminderTimesToTarget()
                }
            ), in: 1...3)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }

    private func iconTile(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentSage.opacity(0.18))
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentSage)
        }
        .frame(width: 40, height: 40)
    }

    // MARK: Cue & Note

    private var cueNoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("CUE & NOTE (OPTIONAL)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            ZStack(alignment: .topLeading) {
                if draft.cueNote.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\u{201C}After I ____, I will ____.\u{201D}")
                            .font(.system(size: 16, design: .serif))
                            .italic()
                            .foregroundStyle(Color.textTertiary)
                        Text("Stack new habits on existing routines.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.top, 4)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $draft.cueNote)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        Color.textTertiary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Color.bgSecondary.opacity(0.5))
                    )
            )
        }
    }

    // MARK: Helper hint

    private var helperHint: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 13))
                .foregroundStyle(Color.accentSage)
            Text("Start with one tiny habit. We can always add more later.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.12))
        )
    }

    // MARK: Helpers

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    /// Returns a binding to the currently-editing slot of `reminderTimes`.
    /// Safe even if the index drifts: returns a no-op binding if out of bounds.
    private func bindingForEditingTime() -> Binding<Date> {
        Binding(
            get: {
                let idx = editingTimeIndex
                if draft.reminderTimes.indices.contains(idx) {
                    return draft.reminderTimes[idx]
                }
                return draft.reminderTimes.first ?? .now
            },
            set: { newValue in
                let idx = editingTimeIndex
                if draft.reminderTimes.indices.contains(idx) {
                    draft.reminderTimes[idx] = newValue
                }
            }
        )
    }

    // MARK: Save

    private func save() async {
        let (schedule, customDays) = draft.resolvedScheduleAndCustomDays
        let trimmedName = draft.name.trimmingCharacters(in: .whitespaces)

        let habit = Habit(
            name: trimmedName,
            iconName: draft.iconName,
            colorTokenName: "accent.sage",
            category: .custom,
            schedule: schedule,
            notificationTimes: draft.notificationsEnabled ? draft.reminderTimes : [],
            sortOrder: 0,
            targetPerDay: max(1, min(draft.targetPerDay, 3)),
            cueNote: draft.cueNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        habit.customDays = customDays

        do {
            try service.add(habit)
        } catch {
            print("❌ Custom habit save failed: \(error)")
            return
        }

        onPlanted(habit)
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
