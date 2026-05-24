import SwiftUI
import SwiftData

// MARK: - QuietHoursSheet
//
// Presented as a bottom sheet from Settings. Edits a local draft so swipe-to-
// dismiss or Cancel discards changes; only Done commits to AppSettings. Each
// presentation starts from the current saved values (stale drafts never linger
// because the draft is seeded in onAppear).

struct QuietHoursSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]

    // Draft state — committed only on Done.
    @State private var enabled = true
    @State private var startHour = 22
    @State private var endHour = 7

    private enum TimeField { case start, end }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    titleBlock
                    if enabled {
                        QuietHoursDial(startHour: $startHour, endHour: $endHour)
                            .frame(height: 300)
                            .padding(.horizontal, Spacing.lg)
                        timeRow
                        presetsBlock
                    } else {
                        offState
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
                .animation(.easeOut(duration: 0.25), value: enabled)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .onAppear(perform: seedDraft)
    }

    // MARK: Header (Cancel / title / Done)

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text("Quiet hours")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button("Done") { commit() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentSage)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("When should Cairn")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text("hold its tongue?")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.accentSage)

            Toggle("", isOn: $enabled)
                .labelsHidden()
                .tint(Color.accentSage)
                .padding(.top, Spacing.sm)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Editable START / END

    private var timeRow: some View {
        HStack(spacing: Spacing.sm) {
            timePill(field: .start, icon: "moon.fill", label: "START", hour: startHour)
            timePill(field: .end, icon: "sun.max.fill", label: "END", hour: endHour)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func timePill(field: TimeField, icon: String, label: String, hour: Int) -> some View {
        Menu {
            Picker("", selection: binding(for: field)) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d:00", h)).tag(h)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentSage)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                Spacer()
                Text(String(format: "%02d:00", hour))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private func binding(for field: TimeField) -> Binding<Int> {
        switch field {
        case .start: return $startHour
        case .end:   return $endHour
        }
    }

    // MARK: Presets

    private var presetsBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("OR PICK A PRESET")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.textTertiary)

            let columns = [GridItem(.flexible(), spacing: Spacing.sm),
                           GridItem(.flexible(), spacing: Spacing.sm)]
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(QuietHoursPreset.allCases) { preset in
                    presetChip(preset)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func presetChip(_ preset: QuietHoursPreset) -> some View {
        let selected = preset.matches(start: startHour, end: endHour)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                startHour = preset.range.start
                endHour = preset.range.end
            }
        } label: {
            HStack(spacing: 6) {
                Text(preset.label)
                    .font(.system(size: 15, weight: .semibold))
                Text("· \(preset.summary)")
                    .font(.system(size: 13))
                    .opacity(0.8)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? Color.white : Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(selected ? Color.accentSage : Color.bgSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Off state

    private var offState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "bell.badge")
                .font(.system(size: 32))
                .foregroundStyle(Color.textTertiary)
            Text("Quiet hours are off")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("Reminders can arrive at any hour. Turn this on to protect your rest.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: Draft lifecycle

    private func seedDraft() {
        enabled = settings.quietHoursEnabled
        startHour = settings.quietHoursStartHour
        endHour = settings.quietHoursEndHour
    }

    private func commit() {
        settings.quietHoursEnabled = enabled
        settings.quietHoursStartHour = startHour
        settings.quietHoursEndHour = endHour
        // Quiet window affects which notifications may fire — reschedule.
        Task { await NotificationService.shared.rescheduleAll(habits, settings: settings) }
        dismiss()
    }
}
