import SwiftUI

/// One row in N1's template list. Layout from the mockup:
///  - sage-tinted icon disc (left)
///  - template name + italic cue (center)
///  - reminder time pill (right, omitted if template has no suggested time)
///  - sage + button (far right)
struct TemplateLibraryRow: View {
    let template: HabitTemplate
    let onAdd: () -> Void

    private var timeString: String? {
        guard let h = template.suggestedHour,
              let m = template.suggestedMinute else { return nil }
        return String(format: "%02d:%02d", h, m)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.accentSage.opacity(0.18))
                Image(systemName: template.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentSage)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if let cue = template.cue {
                    Text(cue)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let time = timeString {
                Text(time)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.accentSage)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.accentSage.opacity(0.18)))
            }

            Button(action: onAdd) {
                ZStack {
                    Circle().fill(Color.accentSage)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(template.name)")
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }
}
