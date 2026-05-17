import SwiftUI
import SwiftData

/// N2 — Configure Habit screen. Shown when the user picks any template (or
/// the Coach Pairing card) from N1. Presented as a full-screen cover.
///
/// Two flavours, driven by `draft.pairingAnchor`:
///  - Plain: opened from a template row. No pairing subtitle, no "Stack on"
///    row, cue note empty by default.
///  - Paired: opened from the Coach Pairing card. Subtitle reads "Coach
///    pairing with X", cue note auto-generated, "Stack on existing habit"
///    row visible at the bottom showing the anchor.
struct ConfigureHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// Called after a successful save. Parent (HomeView) dismisses N2 and N1,
    /// then schedules notifications.
    let onPlanted: (Habit) -> Void

    @State private var draft: ConfigureHabitDraft
    @State private var showTimeSheet = false
    @State private var showDaysSheet = false
    @FocusState private var cueFocused: Bool

    init(
        template: HabitTemplate,
        pairingAnchor: Habit? = nil,
        onPlanted: @escaping (Habit) -> Void
    ) {
        self.onPlanted = onPlanted
        _draft = State(initialValue: ConfigureHabitDraft(
            template: template,
            pairingAnchor: pairingAnchor
        ))
    }

    private var service: HabitService { HabitService(context: context) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    heroBlock
                    whenSection
                    cueNoteSection
                    notificationSection
                    footerHint
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
            ConfigureDaysSheet(draft: draft)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.bgSecondary))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .accessibilityLabel("Back")

            Spacer()

            Text(draft.template.name)
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                Task { await save() }
            } label: {
                Text("Save")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentSage.opacity(draft.canSave ? 1.0 : 0.45)))
            }
            .disabled(!draft.canSave)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Hero (icon + name + subtitle)

    private var heroBlock: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle().fill(Color.accentSage.opacity(0.20))
                Image(systemName: draft.template.iconName)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 96, height: 96)

            Text(draft.template.name)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)

            Text(draft.subtitle)
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }

    // MARK: WHEN section

    private var whenSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("WHEN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                reminderTimeRow
                divider
                daysRow
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

    private var reminderTimeRow: some View {
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
                if let hint = draft.reminderHintPill {
                    Text(hint)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(Color.accentSage)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.accentSage.opacity(0.18)))
                }
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
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.md) {
                    iconTile(systemName: "calendar")
                    Text("DAYS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .tracking(1.4)
                    Spacer()
                    Text(draft.daysSummary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                }

                inlineDayChips
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Read-only day chips inside the Days row, mirroring `selectedDays`.
    /// Tapping a chip is handled by the parent (opening DaysSheet on the whole row).
    private var inlineDayChips: some View {
        HStack(spacing: 6) {
            let order: [Int] = [2, 3, 4, 5, 6, 7, 1] // M T W T F S S
            ForEach(order, id: \.self) { weekday in
                let isOn = draft.selectedDays.contains(weekday)
                Text(initial(for: weekday))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isOn ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isOn ? Color.accentSage : Color.bgTertiary)
                    )
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

    // MARK: CUE & NOTE section

    private var cueNoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("CUE & NOTE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            VStack(alignment: .leading, spacing: Spacing.sm) {
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
                        .frame(minHeight: 72)
                        .focused($cueFocused)
                }

                if draft.pairingAnchor != nil && !draft.cueNote.isEmpty && !cueFocused {
                    Divider().overlay(Color.bgTertiary)
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.accentSage)
                        Text("Auto-generated from your existing routine — tap to edit.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    // MARK: NOTIFICATION section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("NOTIFICATION")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                notificationToggleRow
                if let anchor = draft.pairingAnchor {
                    divider
                    stackOnRow(anchor: anchor)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private var notificationToggleRow: some View {
        HStack(spacing: Spacing.md) {
            iconTile(systemName: "bell")
            VStack(alignment: .leading, spacing: 2) {
                Text("Local nudge")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Once, never twice")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $draft.notificationsEnabled)
                .labelsHidden()
                .tint(Color.accentSage)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }

    private func stackOnRow(anchor: Habit) -> some View {
        HStack(spacing: Spacing.md) {
            iconTile(systemName: "leaf")
            VStack(alignment: .leading, spacing: 2) {
                Text("Stack on existing habit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(anchor.name)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
        // Read-only in v1.0 — anchor is fixed at the time the user picked the
        // pairing. Future versions could let the user reassign.
    }

    // MARK: Footer hint

    private var footerHint: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 13))
                .foregroundStyle(Color.accentSage)
            Group {
                Text("\(habitCountAfterSave) habits")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                + Text(" is still a gentle ceiling. We can pause one anytime.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.12))
        )
    }

    /// "If the user saves now, they'll have N habits." We can't @Query habits
    /// here without bloating the init — instead we look at the model context.
    private var habitCountAfterSave: Int {
        let fetched = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        return fetched.filter { !$0.isArchived }.count + 1
    }

    // MARK: Shared

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

    // MARK: Save

    private func save() async {
        let (schedule, customDays) = draft.resolvedScheduleAndCustomDays
        let habit = Habit(
            name: draft.template.name,
            iconName: draft.template.iconName,
            colorTokenName: draft.template.colorTokenName,
            category: draft.template.category,
            schedule: schedule,
            notificationTimes: draft.notificationsEnabled ? [draft.reminderTime] : [],
            sortOrder: 0,
            targetPerDay: 1,
            cueNote: draft.cueNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        habit.customDays = customDays

        do {
            try service.add(habit)
        } catch {
            print("❌ Configure habit save failed: \(error)")
            return
        }
        onPlanted(habit)
    }
}

// MARK: - Days sheet bound to ConfigureHabitDraft
// Almost identical to CustomDaysSheet but bound to a different draft type.
// Could be generalised behind a protocol; keeping concrete for clarity.

struct ConfigureDaysSheet: View {
    @Bindable var draft: ConfigureHabitDraft
    @Environment(\.dismiss) private var dismiss

    @State private var workingDays: Set<Int>

    init(draft: ConfigureHabitDraft) {
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
