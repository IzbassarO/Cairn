import SwiftUI
import SwiftData

/// Edit screen for an existing habit. Presented as a full-screen cover on
/// top of `HabitInfoView`.
///
/// Field accessibility:
///  - Custom habit: every field is editable (icon, name, schedule, days,
///    notifications, cue note).
///  - Template habit: icon and name are read-only (locked from drift).
///    All schedule/notification/cue fields remain editable.
///
/// Save behavior:
///  - Applies draft to the live `Habit`.
///  - Saves the SwiftData context.
///  - Cancels old notifications and schedules new ones (or cancels entirely
///    if the user turned the toggle off).
///  - Dismisses the cover.
struct HabitEditView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var draft: HabitEditDraft
    @State private var showTimeSheet = false
    @State private var showDaysSheet = false
    @State private var showIconPicker = false

    init(habit: Habit) {
        self.habit = habit
        _draft = State(initialValue: HabitEditDraft(habit: habit))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    iconBlock
                    nameField
                    scheduleCard
                    cueNoteSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .sheet(isPresented: $showTimeSheet) {
            SingleTimeEditorSheet(
                time: $draft.reminderTime,
                slotIndex: 0,
                totalSlots: 1
            )
        }
        .sheet(isPresented: $showDaysSheet) {
            EditDaysSheet(draft: draft)
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(selected: $draft.iconName)
                .presentationDetents([.large])
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(Color.textSecondary)
            .font(.system(size: 16))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.bgSecondary))

            Spacer()

            Text("Edit habit")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                save()
            } label: {
                Text("Save")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.accentSage.opacity(draft.canSave ? 1.0 : 0.45))
                    )
            }
            .disabled(!draft.canSave)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Icon

    private var iconBlock: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                guard !draft.isTemplateBased else { return }
                showIconPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentSage.opacity(0.18))
                    if !draft.isTemplateBased {
                        Circle()
                            .strokeBorder(
                                Color.accentSage.opacity(0.55),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                            )
                    }
                    Image(systemName: draft.iconName)
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(Color.accentSage)
                }
                .frame(width: 96, height: 96)
            }
            .buttonStyle(.plain)
            .disabled(draft.isTemplateBased)

            if !draft.isTemplateBased {
                Text("TAP TO CHANGE ICON")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }

    // MARK: Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("NAME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            if draft.isTemplateBased {
                // Locked: show the name as static text in a quieter style.
                HStack {
                    Text(draft.name)
                        .font(.system(size: 18, design: .serif))
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Color.bgSecondary)
                )
                Text("Template names stay fixed — keeps your data clean over time.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.leading, Spacing.xs)
            } else {
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
            }
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
                reminderRow
                divider
                daysRow
                divider
                notificationToggleRow
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

    private var reminderRow: some View {
        let disabled = !draft.notificationsEnabled
        return Button {
            showTimeSheet = true
        } label: {
            HStack(spacing: Spacing.md) {
                iconTile(systemName: "clock")
                VStack(alignment: .leading, spacing: 2) {
                    Text("REMINDER TIME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .tracking(1.4)
                    Text(draft.reminderTimeLabel)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
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
                    Text("\u{201C}After I ____, I will ____.\u{201D}")
                        .font(.system(size: 16, design: .serif))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $draft.cueNote)
                    .font(.system(size: 16, design: .serif))
                    .italic()
                    .foregroundStyle(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    // MARK: Save

    private func save() {
        draft.apply()
        do {
            try context.save()
        } catch {
            print("❌ Edit save failed: \(error)")
            return
        }

        // Reschedule notifications. Cancel any existing scheduled ones first,
        // then if notifications are enabled, schedule fresh.
        let id = habit.id
        let updated = habit
        Task { @MainActor in
            NotificationService.shared.cancel(habitId: id)
            if !updated.notificationTimes.isEmpty {
                await NotificationService.shared.ensureAuthorizedThenSchedule(updated)
            }
        }

        dismiss()
    }
}

// MARK: - Days sheet bound to HabitEditDraft
// Same shape as ConfigureDaysSheet but bound to HabitEditDraft. Kept concrete
// for clarity — a generic over a draft protocol would save ~50 lines but cost
// readability.

struct EditDaysSheet: View {
    @Bindable var draft: HabitEditDraft
    @Environment(\.dismiss) private var dismiss

    @State private var workingDays: Set<Int>

    init(draft: HabitEditDraft) {
        self.draft = draft
        _workingDays = State(initialValue: draft.selectedDays)
    }

    private let displayOrder: [Int] = [2, 3, 4, 5, 6, 7, 1]

    private struct Pattern: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
        let days: Set<Int>
    }

    private let patterns: [Pattern] = [
        .init(id: "daily", title: "Every day", subtitle: "7 / week", days: Set(1...7)),
        .init(id: "weekdays", title: "Weekdays only", subtitle: "Mon — Fri", days: [2, 3, 4, 5, 6]),
        .init(id: "weekends", title: "Weekends only", subtitle: "Sat, Sun", days: [1, 7]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    dayChipsRow.padding(.top, Spacing.md)
                    patternsList.padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.sheet)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.textSecondary)
                .font(.system(size: 16))
            Spacer()
            Text("Which days?")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button("Done") {
                draft.selectedDays = workingDays.isEmpty ? Set(1...7) : workingDays
                dismiss()
            }
            .foregroundStyle(Color.accentSage)
            .font(.system(size: 16, weight: .semibold))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }

    private var dayChipsRow: some View {
        HStack(spacing: 8) {
            ForEach(displayOrder, id: \.self) { weekday in
                let isOn = workingDays.contains(weekday)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        if isOn { workingDays.remove(weekday) } else { workingDays.insert(weekday) }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(initial(for: weekday))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isOn ? Color.white : Color.textSecondary)
                        Image(systemName: isOn ? "checkmark" : "")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isOn ? Color.white : Color.clear)
                            .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isOn ? Color.accentSage : Color.bgSecondary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func initial(for weekday: Int) -> String {
        switch weekday {
        case 2: return "M"; case 3: return "T"; case 4: return "W"
        case 5: return "T"; case 6: return "F"; case 7: return "S"
        case 1: return "S"
        default: return "?"
        }
    }

    private var patternsList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("COMMON PATTERNS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .tracking(1.6)
                .padding(.leading, Spacing.xs)

            VStack(spacing: Spacing.sm) {
                ForEach(patterns) { pattern in
                    let isActive = workingDays == pattern.days
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            workingDays = pattern.days
                        }
                    } label: {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        isActive ? Color.clear : Color.textTertiary.opacity(0.4),
                                        lineWidth: 1.5
                                    )
                                if isActive {
                                    Circle().fill(Color.accentSage)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                                Text(pattern.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .fill(isActive ? Color.accentSage.opacity(0.15) : Color.bgSecondary)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
