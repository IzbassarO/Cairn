import SwiftUI

/// Overlay shown briefly between F1 dismissal and the iOS system notification
/// alert (the F4 moment in the design). The card explains why we want
/// permission before the OS opens its own dialog — a soft pre-prompt pattern
/// that's known to improve grant rates without coercing.
///
/// The view itself does not call `requestAuthorization`. The presenter (HomeView)
/// is responsible for: showing this view → waiting → triggering the alert →
/// hiding this view. That keeps notification logic in one place.
struct PrePermissionView: View {
    var body: some View {
        ZStack(alignment: .top) {
            // Dim everything underneath, matching the F4 mock where the
            // background is grayed out.
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            card
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
        // Block taps so the user can't accidentally interact with the dimmed
        // app while the system alert is about to appear.
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                ZStack {
                    Circle().fill(Color.accentSage.opacity(0.18))
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentSage)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("GENTLE REMINDERS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentSage)
                        .tracking(1.4)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("One quiet nudge,")
                            .font(.system(size: 19, weight: .bold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                        Text("at the time you chose.")
                            .font(.system(size: 19, weight: .bold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }

            Text("We'll only ping you once per habit per day — never twice, never guilt-tripping. You can change this anytime in Settings.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgPrimary)
                .shadow(color: .black.opacity(0.20), radius: 24, y: 8)
        )
    }
}
