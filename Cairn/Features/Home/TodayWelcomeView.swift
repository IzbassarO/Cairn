import SwiftUI
import SwiftData

struct TodayWelcomeView: View {
    /// Called when the first-habit flow finishes saving. Parent (HomeView) decides
    /// whether to present F5 — TodayWelcomeView will be torn down the moment
    /// SwiftData reports `habits.isEmpty == false`, so it cannot host the cover.
    let onFirstHabitPlanted: (PlantedHabitContext) -> Void

    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedFirstHabit") private var hasCompletedFirstHabit: Bool = false
    @Query private var habits: [Habit]
    @State private var showCreation = false

    /// When non-nil, the F1 sheet for this template is presented.
    @State private var pendingTemplate: HabitTemplate?

    /// Today schedule cover (Day View timeline). Opened from the calendar icon
    /// in TodayHeader. On welcome screen it'll just show the empty state —
    /// but we still let the user open it, so the icon doesn't feel dead.
    @State private var showTodaySchedule = false

    /// Reminders inbox cover. Same story — empty state on welcome screen.
    @State private var showRemindersInbox = false

    private var service: HabitService { HabitService(context: context) }
    private var starters: [HabitTemplate] { HabitTemplates.gentleStarters }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                stoneHero
                pitch
                gentleStarters
                customCTA
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .fullScreenCover(isPresented: $showCreation) {
            CustomHabitView { habit in
                handlePlanted(habit)
            }
        }
        .fullScreenCover(isPresented: $showTodaySchedule) {
            TodayScheduleView()
        }
        .fullScreenCover(isPresented: $showRemindersInbox) {
            RemindersInboxView()
        }
        .sheet(item: $pendingTemplate) { template in
            FirstHabitSheet(template: template) { habit in
                handlePlanted(habit)
            }
        }
    }

    // MARK: Header
    // Uses the shared TodayHeader so welcome and returning states are visually
    // consistent. The greeting picks up time-of-day automatically. Both header
    // buttons are wired even on the welcome screen — they open the same
    // Schedule / Reminders screens, which gracefully show empty states.

    private var header: some View {
        TodayHeader(
            onCalendarTap: { showTodaySchedule = true },
            onBellTap: { showRemindersInbox = true }
        )
    }

    // MARK: Stone hero

    private var stoneHero: some View {
        HStack {
            Spacer()
            RestingStoneView(width: 170)
                .padding(.vertical, Spacing.md)
            Spacer()
        }
    }

    // MARK: Pitch

    private var pitch: some View {
        VStack(spacing: Spacing.sm) {
            Text("A BLANK GARDEN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .textCase(.uppercase)
                .tracking(1.6)

            VStack(spacing: 0) {
                Text("Pick your first stone.")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("It can be tiny.")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
                    .multilineTextAlignment(.center)
            }

            Text("A small habit — sip water, breathe once, take meds — to anchor your day. We'll grow from here.")
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Gentle starters

    private var gentleStarters: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("COACH'S GENTLE STARTERS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .textCase(.uppercase)
                .tracking(1.6)
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(starters.enumerated()), id: \.element.id) { index, template in
                    starterRow(template)
                    if index < starters.count - 1 {
                        Divider()
                            .overlay(Color.bgTertiary)
                            .padding(.leading, 72)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private func starterRow(_ template: HabitTemplate) -> some View {
        HStack(spacing: Spacing.md) {
            // Icon disc.
            Image(systemName: template.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.accentSage)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.accentSage.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(template.cue ?? template.blurb)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                pendingTemplate = template
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.accentSage.opacity(0.18)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(template.name)")
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: Custom CTA

    private var customCTA: some View {
        Button {
            showCreation = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Write a custom habit")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.accentSage))
            .shadow(color: Color.accentSage.opacity(0.25), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func handlePlanted(_ habit: Habit) {
        // Close whichever entry surface is open (template path or custom path).
        // We do NOT present F5 from here — by the time the 0.45s "let the
        // sheet dismiss" delay elapses, SwiftData has updated @Query and
        // HomeView has already swapped us out for the returning-user list,
        // tearing us down. The parent (HomeView) holds the cover instead.
        pendingTemplate = nil
        showCreation = false

        // First-time celebration only.
        guard !hasCompletedFirstHabit else { return }
        hasCompletedFirstHabit = true

        let context = PlantedHabitContext(
            habit: habit,
            habitName: habit.name,
            timeLabel: formatTime(habit.notificationTimes.first),
            daysLabel: scheduleLabel(habit),
            notificationsOn: !habit.notificationTimes.isEmpty
        )
        onFirstHabitPlanted(context)
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func scheduleLabel(_ habit: Habit) -> String {
        switch habit.schedule {
        case .daily: return "Every day"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom:
            // Compact: count of selected days, e.g. "4 / week"
            return "\(habit.customDays.count) / week"
        }
    }
}
