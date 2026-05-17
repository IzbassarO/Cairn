import SwiftUI

/// Top block of the Today screen. Visual model from mockup T:
///  - Eyebrow: `☀ Morning · Thu, Nov 14`
///  - Greeting: `Good morning,` (line 1) / `Izbassar.` (line 2 italic sage)
///  - Right side: two round white buttons (calendar + bell with optional badge)
///
/// The time-of-day icon and word in the eyebrow rotate with the current hour:
/// Morning / Afternoon / Evening / Night. The greeting word mirrors that.
struct TodayHeader: View {
    @AppStorage("userDisplayName") private var displayName: String = ""

    /// Notification badge count. Reserved for v1.1 — for now always 0.
    /// Pass a non-zero number to display the coral dot with that count.
    var notificationBadgeCount: Int = 0

    /// Tap handler for the calendar button. When nil, the button is decorative.
    var onCalendarTap: (() -> Void)? = nil
    /// Tap handler for the bell button. When nil, the button is decorative.
    var onBellTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                eyebrow
                Text(greetingPrefix + ",")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(displayedName)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: Spacing.sm)

            HStack(spacing: Spacing.sm) {
                topBarButton(icon: "calendar", action: onCalendarTap)
                ZStack(alignment: .topTrailing) {
                    topBarButton(icon: "bell", action: onBellTap)
                    if notificationBadgeCount > 0 {
                        Text("\(notificationBadgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentCoral))
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: Eyebrow

    private var eyebrow: some View {
        HStack(spacing: 6) {
            Image(systemName: timeOfDayIcon)
                .font(.system(size: 12))
                .foregroundStyle(Color.accentSage)
            Text(timeOfDayLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentSage)
            Text("·")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
            Text(dateLine)
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var timeOfDayLabel: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }

    private var timeOfDayIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "sun.max"
        case 12..<17: return "sun.haze"
        case 17..<22: return "sunset"
        default: return "moon.stars"
        }
    }

    private var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello, late one"
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: .now)
    }

    // MARK: Name

    private var displayedName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "friend." : "\(trimmed)."
    }

    // MARK: Top-bar button

    /// When `action` is nil, renders a static decorative icon. When provided,
    /// wraps in a Button so the icon is tappable.
    @ViewBuilder
    private func topBarButton(icon: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                topBarIcon(icon)
            }
            .buttonStyle(.plain)
        } else {
            topBarIcon(icon)
                .accessibilityHidden(true)
        }
    }

    private func topBarIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.accentSage)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.white))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
