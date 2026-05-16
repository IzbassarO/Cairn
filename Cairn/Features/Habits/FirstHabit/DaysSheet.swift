import SwiftUI

struct DaysSheet: View {
    @Bindable var draft: FirstHabitDraft
    @Environment(\.dismiss) private var dismiss

    /// Local working copy — commits on Done.
    @State private var workingDays: Set<Int>

    init(draft: FirstHabitDraft) {
        self.draft = draft
        _workingDays = State(initialValue: draft.selectedDays)
    }

    // Display order: M T W T F S S (weekday ints 2,3,4,5,6,7,1)
    private let displayOrder: [Int] = [2, 3, 4, 5, 6, 7, 1]

    private struct Pattern: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
        let days: Set<Int>
    }

    private let patterns: [Pattern] = [
        .init(id: "daily",    title: "Every day",     subtitle: "7 / week",  days: Set(1...7)),
        .init(id: "weekdays", title: "Weekdays only", subtitle: "Mon — Fri", days: [2, 3, 4, 5, 6]),
        .init(id: "weekends", title: "Weekends only", subtitle: "Sat, Sun",  days: [1, 7]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headline
                        .padding(.top, Spacing.md)
                    dayChipsRow
                    patternsList
                        .padding(.bottom, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDetents([.fraction(0.72)])
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

            Text("Which days?")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button("Done") {
                // Don't allow an empty selection to be committed; if user untoggled
                // everything we fall back to "Every day" rather than blocking Done.
                draft.selectedDays = workingDays.isEmpty ? Set(1...7) : workingDays
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
            HStack(spacing: 6) {
                Text("Every day")
                    .italic()
                    .foregroundStyle(Color.accentSage)
                Text("works for meds.")
                    .foregroundStyle(Color.textPrimary)
            }
            .font(.system(size: 22, weight: .bold, design: .serif))

            Text("You can tap any to skip.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .padding(.top, 2)
        }
    }

    // MARK: Day chips

    private var dayChipsRow: some View {
        HStack(spacing: 8) {
            ForEach(displayOrder, id: \.self) { weekday in
                dayChip(weekday: weekday)
            }
        }
    }

    private func dayChip(weekday: Int) -> some View {
        let isOn = workingDays.contains(weekday)

        return Button {
            toggle(weekday)
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
        .accessibilityLabel("\(fullName(for: weekday)), \(isOn ? "selected" : "not selected")")
    }

    private func initial(for weekday: Int) -> String {
        // M T W T F S S — both Thursday and Tuesday show "T", Saturday and Sunday show "S".
        switch weekday {
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "T"
        case 6: return "F"
        case 7: return "S"
        case 1: return "S"
        default: return "?"
        }
    }

    private func fullName(for weekday: Int) -> String {
        FirstHabitDraft.shortDayLabel(weekday: weekday)
    }

    private func toggle(_ weekday: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            if workingDays.contains(weekday) {
                workingDays.remove(weekday)
            } else {
                workingDays.insert(weekday)
            }
        }
    }

    // MARK: Patterns

    private var patternsList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("COMMON PATTERNS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .tracking(1.6)
                .padding(.leading, Spacing.xs)
                .padding(.top, Spacing.sm)

            VStack(spacing: Spacing.sm) {
                ForEach(patterns) { pattern in
                    patternRow(pattern)
                }
            }
        }
    }

    private func patternRow(_ pattern: Pattern) -> some View {
        let isActive = workingDays == pattern.days

        return Button {
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
