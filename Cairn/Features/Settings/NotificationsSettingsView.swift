import SwiftUI
import UserNotifications

/// Notifications settings page. Reached from the Notifications row in Settings.
///
/// What it manages:
///  - **App-level preference** (`@AppStorage("notificationsEnabled")`):
///    user's intent. When false, NotificationService skips scheduling.
///  - **iOS-level permission**: not editable here. We surface the state and
///    deep-link to system Settings when denied.
///
/// The reason we have an app-level toggle separate from the iOS permission:
/// some users want to pause nudges temporarily (going on vacation, sick week,
/// etc) without revoking permission entirely. Easier UX, fewer re-grants.
struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    @State private var iosAuthState: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock

                    masterCard

                    if iosAuthState == .denied {
                        deniedHint
                    }

                    aboutCopy
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .task { await refreshAuthState() }
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
            Text("Notifications")
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
                Text("Gentle")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("nudges.")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
            Text("Cairn nudges once per habit, never twice in a row.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Master card

    private var masterCard: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "bell",
                label: "Allow notifications",
                trailing: .toggle(isOn: $notificationsEnabled)
            )
            Divider().overlay(Color.bgTertiary).padding(.leading, 64)
            HStack {
                Text("iOS permission")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text(iosStatusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iosStatusColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private var iosStatusLabel: String {
        switch iosAuthState {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied: return "Not allowed"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }

    private var iosStatusColor: Color {
        switch iosAuthState {
        case .authorized, .provisional, .ephemeral: return .accentSage
        case .denied: return .accentCoral
        case .notDetermined: return .textTertiary
        @unknown default: return .textTertiary
        }
    }

    // MARK: Denied hint

    private var deniedHint: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notifications are off in iOS Settings.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("Reminders will be silent until you re-enable them.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
            Button {
                openSystemSettings()
            } label: {
                Text("Open iOS Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentSage))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentCoral.opacity(0.10))
        )
    }

    // MARK: About copy

    private var aboutCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How Cairn nudges")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("One reminder per habit at the time you set. If you've already placed today's stone, the reminder doesn't fire — never twice in one day.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Helpers

    private func refreshAuthState() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        await MainActor.run {
            iosAuthState = settings.authorizationStatus
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
