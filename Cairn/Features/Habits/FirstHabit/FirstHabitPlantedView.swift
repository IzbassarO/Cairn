import SwiftUI

struct FirstHabitPlantedView: View {
    let habitName: String
    let timeLabel: String
    let daysLabel: String
    let notificationsOn: Bool
    let onSeeToday: () -> Void
    let onPlantAnother: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sparkleAppear = false
    @State private var stoneTrigger = 0

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        stoneHero
                            .padding(.top, Spacing.lg)
                        textBlock
                        summaryChips
                            .padding(.top, Spacing.sm)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }

                Spacer(minLength: 0)

                ctaBlock
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .onAppear {
            stoneTrigger += 1
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    sparkleAppear = true
                }
            } else {
                sparkleAppear = true
            }
        }
    }

    // MARK: Top bar (just the X)

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                onSeeToday()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.bgSecondary))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .accessibilityLabel("Close")
            .padding(.trailing, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: Stone hero + sparkles

    private var stoneHero: some View {
        ZStack {
            sparkles
                .opacity(sparkleAppear ? 1 : 0)
            AnimatedStoneView(
                tint: Color.accentSage,
                width: 180,
                trigger: stoneTrigger
            )
        }
        .frame(height: 220)
        .accessibilityHidden(true)
    }

    private var sparkles: some View {
        ZStack {
            sparkle(x: -90, y: -70, size: 14, opacity: 0.9)
            sparkle(x:  90, y: -50, size: 11, opacity: 0.7)
            sparkle(x: -60, y:  10, size:  9, opacity: 0.6)
            sparkle(x:  80, y:  30, size: 12, opacity: 0.8)
            sparkle(x:   0, y: -95, size: 10, opacity: 0.8)
            sparkle(x: -30, y: -60, size:  7, opacity: 0.5)
        }
    }

    private func sparkle(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundStyle(Color.accentSage.opacity(opacity))
            .offset(x: x, y: y)
    }

    // MARK: Text block

    private var textBlock: some View {
        VStack(spacing: Spacing.sm) {
            Text("YOUR FIRST STONE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.6)

            VStack(spacing: 0) {
                Text("\(habitName),")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("planted.")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }

            Text(reminderCopy)
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
        }
    }

    private var reminderCopy: AttributedString {
        // Bold the time inside the otherwise gentle sentence.
        let base: String = notificationsOn
            ? "We'll quietly remind you at \(timeLabel) tomorrow. Place the stone when you've done it — that's the whole thing."
            : "No reminder for this one. Place the stone when you've done it — that's the whole thing."

        var attr = AttributedString(base)
        if notificationsOn, let range = attr.range(of: timeLabel) {
            attr[range].font = .system(size: 15, weight: .bold)
            attr[range].foregroundColor = Color.textPrimary
        }
        return attr
    }

    // MARK: Summary chips

    private var summaryChips: some View {
        HStack(spacing: 0) {
            summaryChip(icon: "clock", label: notificationsOn ? timeLabel : "No time")
            chipDivider
            summaryChip(icon: "calendar", label: daysLabel)
            chipDivider
            summaryChip(icon: "bell", label: notificationsOn ? "Gentle nudge" : "Silent")
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func summaryChip(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.accentSage)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }

    private var chipDivider: some View {
        Rectangle()
            .fill(Color.bgTertiary)
            .frame(width: 1, height: 28)
    }

    // MARK: CTA block

    private var ctaBlock: some View {
        VStack(spacing: Spacing.md) {
            Button(action: onSeeToday) {
                Text("See my Today")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(Color.accentSage))
                    .shadow(color: Color.accentSage.opacity(0.25), radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Button(action: onPlantAnother) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Plant another habit")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.accentSage)
            }
            .buttonStyle(.plain)
        }
    }
}
