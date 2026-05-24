import SwiftUI
import SwiftData
import UserNotifications
import Combine

struct NotificationsSettingsView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var habits: [Habit]

    @State private var iosAuthState: UNAuthorizationStatus = .notDetermined
    /// Drives the live countdown while a pause is active.
    @State private var now: Date = Date()

    /// Ticks every second so the red countdown stays real-time.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private func close() { if let onClose { onClose() } else { dismiss() } }

    /// Re-applies notification scheduling to match the current app state.
    private func applyScheduling() {
        Task { await NotificationService.shared.rescheduleAll(habits, settings: settings) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock

                    masterCard

                    if settings.notificationsEnabled {
                        if settings.isNotificationsPaused {
                            activePauseCard
                        } else {
                            pausePresetsCard
                        }
                    }

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
        .onReceive(ticker) { t in
            // Only bother updating while a pause is counting down.
            guard settings.isNotificationsPaused else { return }
            let wasPaused = settings.notificationsPausedUntil
            now = t
            // If this tick crossed the resume time, the computed pause flips to
            // nil on its own (expired pauses read as nil). Reschedule once so
            // reminders come back without the user reopening this screen.
            if wasPaused != nil, !settings.isNotificationsPaused {
                applyScheduling()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                close()
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
                trailing: .toggle(isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { newValue in
                        settings.notificationsEnabled = newValue
                        // Turning the master off clears any timed pause —
                        // "off" already covers it, no need for a dangling timer.
                        if !newValue { settings.resumeNotifications() }
                        applyScheduling()
                    }
                ))
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

    // MARK: Pause presets (shown when ON and not paused)

    private var pausePresetsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentSage)
                Text("PAUSE FOR A WHILE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(0.5)
            }
            Text("Mute every reminder for a set time, then they come back on their own.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.sm) {
                ForEach(NotificationPause.allCases) { preset in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            settings.pauseNotifications(preset)
                            now = Date()
                        }
                        applyScheduling()
                    } label: {
                        Text(preset.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.accentSage)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                                    .fill(Color.accentSage.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Active pause card (live countdown)

    private var activePauseCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentCoral)
                Text("Notifications paused")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Resuming in")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                Text(countdownString)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.accentCoral)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text(resumeAtString)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    settings.resumeNotifications()
                }
                applyScheduling()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Resume now")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Capsule().fill(Color.accentSage))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentCoral.opacity(0.10))
        )
    }

    private var countdownString: String {
        guard let until = settings.notificationsPausedUntil else { return "—" }
        let remaining = max(0, until.timeIntervalSince(now))
        let total = Int(remaining)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if days > 0 {
            return String(format: "%dd %02d:%02d:%02d", days, hours, minutes, seconds)
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var resumeAtString: String {
        guard let until = settings.notificationsPausedUntil else { return "" }
        let f = DateFormatter()
        let cal = Calendar.current
        if cal.isDateInToday(until) {
            f.dateFormat = "'today at' HH:mm"
        } else if cal.isDateInTomorrow(until) {
            f.dateFormat = "'tomorrow at' HH:mm"
        } else {
            f.dateFormat = "EEE d MMM 'at' HH:mm"
        }
        return f.string(from: until)
    }

    // MARK: iOS status

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
        let iosSettings = await center.notificationSettings()
        await MainActor.run {
            iosAuthState = iosSettings.authorizationStatus
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
