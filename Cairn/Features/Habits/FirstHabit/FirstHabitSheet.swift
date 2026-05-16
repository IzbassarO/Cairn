import SwiftUI
import SwiftData

struct FirstHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let template: HabitTemplate
    /// Called after a successful save. The parent uses this to dismiss
    /// the sheet and present the celebration (F5).
    let onPlanted: (Habit) -> Void

    @State private var draft: FirstHabitDraft
    @State private var showTimeSheet = false
    @State private var showDaysSheet = false

    init(template: HabitTemplate, onPlanted: @escaping (Habit) -> Void) {
        self.template = template
        self.onPlanted = onPlanted
        _draft = State(initialValue: FirstHabitDraft(template: template))
    }

    private var service: HabitService { HabitService(context: context) }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    templateBlock
                    blurb
                    configCard
                    helperHint
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            plantCTA
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDetents([.fraction(0.78)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.sheet)
        .sheet(isPresented: $showTimeSheet) {
            ReminderTimeSheet(draft: draft)
        }
        .sheet(isPresented: $showDaysSheet) {
            DaysSheet(draft: draft)
        }
    }

    // MARK: Header (Cancel · Your first habit)

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.textSecondary)
                .font(.system(size: 16))

            Spacer()

            Text("Your first habit")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Invisible placeholder so the title stays centered.
            Text("Cancel")
                .font(.system(size: 16))
                .opacity(0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }

    // MARK: Template block (icon + eyebrow + name)

    private var templateBlock: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.accentSage.opacity(0.18))
                Image(systemName: template.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text("COACH'S GENTLE STARTER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentSage)
                    .tracking(1.4)
                Text(template.name)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()
        }
    }

    // MARK: Blurb

    private var blurb: some View {
        let cue = template.cue.map { "\($0) — " } ?? ""
        return Text("\u{201C}\(cue)\(template.blurb)\u{201D}")
            .font(.system(size: 15, design: .serif))
            .italic()
            .foregroundStyle(Color.textSecondary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Config card (3 rows)

    private var configCard: some View {
        VStack(spacing: 0) {
            configRow(
                icon: "clock",
                eyebrow: "REMINDER TIME",
                value: draft.reminderTimeLabel,
                showChevron: true,
                disabled: !draft.notificationsEnabled
            ) {
                showTimeSheet = true
            }

            Divider().overlay(Color.bgTertiary).padding(.leading, 72)

            configRow(
                icon: "calendar",
                eyebrow: "DAYS",
                value: draft.daysSummary,
                showChevron: true,
                disabled: false
            ) {
                showDaysSheet = true
            }

            Divider().overlay(Color.bgTertiary).padding(.leading, 72)

            // Notification toggle row — no tap-to-open, has a Toggle on the right.
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
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func configRow(
        icon: String,
        eyebrow: String,
        value: String,
        showChevron: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                iconTile(systemName: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .tracking(1.4)
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(disabled ? Color.textTertiary : Color.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
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

    // MARK: Helper hint

    private var helperHint: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 13))
                .foregroundStyle(Color.accentSage)
            Text("You can change all of this later, in Settings.")
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

    // MARK: Plant CTA

    private var plantCTA: some View {
        Button {
            plant()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 15))
                Text("Plant this habit")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.accentSage.opacity(draft.canSave ? 1.0 : 0.4)))
            .shadow(color: Color.accentSage.opacity(draft.canSave ? 0.25 : 0), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!draft.canSave)
    }

    // MARK: Save

    private func plant() {
        let (schedule, customDays) = draft.resolvedScheduleAndCustomDays

        let habit = Habit(
            name: draft.templateName,
            iconName: draft.templateIcon,
            colorTokenName: draft.templateColorToken,
            category: draft.templateCategory,
            schedule: schedule,
            notificationTimes: draft.notificationsEnabled ? [draft.reminderTime] : [],
            sortOrder: 0
        )
        habit.customDays = customDays

        do {
            try service.add(habit)
        } catch {
            print("❌ Plant failed: \(error)")
            return
        }

        // Hand the habit off to the parent. The parent (HomeView) orchestrates
        // everything that happens after — F1 dismissal, pre-permission overlay,
        // system alert, notification scheduling, and the F5 celebration.
        //
        // We deliberately do NOT run any of that here because overlays and
        // covers cannot reliably present on top of a sheet that's about to
        // dismiss.
        onPlanted(habit)
    }
}
