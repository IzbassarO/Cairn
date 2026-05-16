import SwiftUI

struct ReminderTimeSheet: View {
    @Bindable var draft: FirstHabitDraft
    @Environment(\.dismiss) private var dismiss

    /// Local working copy — only commits on Done.
    @State private var workingTime: Date

    init(draft: FirstHabitDraft) {
        self.draft = draft
        _workingTime = State(initialValue: draft.reminderTime)
    }

    private struct Moment: Identifiable, Equatable {
        let id: String
        let label: String
        let icon: String
        let hour: Int
        let minute: Int
    }

    private let moments: [Moment] = [
        .init(id: "morning", label: "Morning",  icon: "sun.max",  hour: 8,  minute: 30),
        .init(id: "midday",  label: "Midday",   icon: "clock",    hour: 13, minute: 0),
        .init(id: "evening", label: "Evening",  icon: "sunset",   hour: 19, minute: 0),
        .init(id: "bedtime", label: "Bedtime",  icon: "moon",     hour: 22, minute: 0),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headline
                        .padding(.top, Spacing.md)
                    wheel
                    momentsGrid
                        .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDetents([.fraction(0.62)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.sheet)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.textSecondary)
                .font(.system(size: 16))

            Spacer()

            Text("Reminder time")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button("Done") {
                draft.reminderTime = workingTime
                dismiss()
            }
            .foregroundStyle(Color.accentSage)
            .font(.system(size: 16, weight: .semibold))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 2) {
            Text("When should I")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text("quietly nudge you?")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.accentSage)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Wheel

    private var wheel: some View {
        DatePicker(
            "",
            selection: $workingTime,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Moments grid

    private var momentsGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("OR PICK A MOMENT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .tracking(1.6)
                .padding(.leading, Spacing.xs)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.sm),
                          GridItem(.flexible(), spacing: Spacing.sm)],
                spacing: Spacing.sm
            ) {
                ForEach(moments) { moment in
                    momentChip(moment)
                }
            }
        }
    }

    private func momentChip(_ m: Moment) -> some View {
        let isActive = isCurrent(moment: m)
        let timeText = String(format: "%02d:%02d", m.hour, m.minute)

        return Button {
            applyMoment(m)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: m.icon)
                    .font(.system(size: 13))
                Text("\(m.label) · \(timeText)")
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isActive ? Color.white : Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, Spacing.sm)
            .background(
                Capsule().fill(isActive ? Color.accentSage : Color.bgSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private func isCurrent(moment: Moment) -> Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: workingTime)
        return comps.hour == moment.hour && comps.minute == moment.minute
    }

    private func applyMoment(_ m: Moment) {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: workingTime)
        comps.hour = m.hour
        comps.minute = m.minute
        if let date = Calendar.current.date(from: comps) {
            withAnimation(.easeInOut(duration: 0.2)) {
                workingTime = date
            }
        }
    }
}
