import SwiftUI

/// Picker for the "quiet hours" window — a daily time range during which
/// notifications are suppressed. Default 22:00 - 07:00 (mockup I).
///
/// Stored as three @AppStorage values:
///  - `quietHoursEnabled: Bool` (default true for ADHD UX safety — better
///    not to wake users in the middle of the night)
///  - `quietHoursStartHour: Int` (0-23, default 22)
///  - `quietHoursEndHour: Int` (0-23, default 7)
///
/// NotificationService consumption (next request): when scheduling a habit
/// reminder, check if the reminder time falls inside the quiet window. If
/// yes, push the trigger time to `endHour:00` on the next applicable day.
struct QuietHoursView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quietHoursEnabled") private var enabled: Bool = true
    @AppStorage("quietHoursStartHour") private var startHour: Int = 22
    @AppStorage("quietHoursEndHour") private var endHour: Int = 7

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock
                    masterToggle
                    if enabled {
                        rangeCard
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        previewLine
                    }
                    aboutCopy
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
                .animation(.easeOut(duration: 0.25), value: enabled)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
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
                    Text("Settings")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            Spacer()
            Text("Quiet hours")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("No nudges")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("at night.")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
            Text("Reminders pause during this window and resume the next morning.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
        }
    }

    // MARK: Master toggle

    private var masterToggle: some View {
        SettingsRow(
            icon: "moon",
            label: "Quiet hours",
            trailing: .toggle(isOn: $enabled)
        )
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Range card

    private var rangeCard: some View {
        VStack(spacing: 0) {
            hourRow(label: "From", icon: "moon.stars", hour: $startHour)
            Divider().overlay(Color.bgTertiary).padding(.leading, 64)
            hourRow(label: "Until", icon: "sun.max", hour: $endHour)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func hourRow(label: String, icon: String, hour: Binding<Int>) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentSage.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 34, height: 34)

            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Custom-styled date picker showing only the hour. We use a Picker
            // wrapped in a Menu so the trigger looks like our other sage pills.
            Menu {
                ForEach(0..<24, id: \.self) { h in
                    Button {
                        hour.wrappedValue = h
                    } label: {
                        Text(formatHour(h))
                    }
                }
            } label: {
                Text(formatHour(hour.wrappedValue))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.accentSage)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentSage.opacity(0.18)))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }

    private func formatHour(_ h: Int) -> String {
        String(format: "%02d:00", h)
    }

    // MARK: Preview / about

    /// "Reminders pause from 22:00 to 07:00 — that's about 9 hours of rest."
    private var previewLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
            Text(previewString)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
    }

    private var previewString: String {
        let span = quietSpanHours()
        let spanStr = span == 1 ? "1 hour" : "\(span) hours"
        return "From \(formatHour(startHour)) to \(formatHour(endHour)) — about \(spanStr) of rest."
    }

    /// Forward span in hours from start → end, wrapping over midnight.
    private func quietSpanHours() -> Int {
        let raw = endHour - startHour
        return raw > 0 ? raw : raw + 24
    }

    private var aboutCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Why this matters")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("Sleep is half of any habit. Nudges during quiet hours get held until morning — never lost, never repeated.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, Spacing.md)
    }
}
