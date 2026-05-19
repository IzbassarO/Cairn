import SwiftUI
import SwiftData

/// Settings root. v1 is local-only and free — no monetization, no Sign in
/// with Apple, no iCloud sync. The screen is structured to walk a user
/// from identity → functional preferences → polish → utility → legal:
///
///  1. **Profile card** (top): name + total stones, taps → ProfileView
///  2. **Personal**: Your Why, Your name — identity hooks that compound
///     retention. A user who's written their "why" and named themselves is
///     much harder to lose to the App Store's next dopamine hit.
///  3. **Habits & Reminders**: Notifications, Reminder style, Quiet hours,
///     Haptic feedback
///  4. **Appearance**: App icon, Theme, Text size
///  5. **Data**: Export, Delete all
///  6. **About**: About Cairn, Privacy, Terms
///
/// All preferences persist via @AppStorage immediately. Real screens for
/// some rows ship in subsequent requests — for now we route to placeholder
/// covers so no button is dead.
struct SettingsView: View {
    @AppStorage("userDisplayName") private var displayName: String = ""
    @AppStorage("userWhy") private var userWhy: String = ""
    @Query private var habits: [Habit]

    // MARK: - Persisted preferences

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderStyle") private var reminderStyleRaw: String = ReminderStyle.gentle.rawValue
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled: Bool = true
    @AppStorage("quietHoursStartHour") private var quietHoursStartHour: Int = 22
    @AppStorage("quietHoursEndHour") private var quietHoursEndHour: Int = 7
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true

    @AppStorage("themePreference") private var themeRaw: String = ThemePreference.system.rawValue
    @AppStorage("textSize") private var textSizeRaw: String = TextSize.standard.rawValue
    @AppStorage("appIconName") private var appIconName: String = "Default"

    // MARK: - Navigation state

    @State private var showProfile = false
    @State private var showYourWhy = false
    @State private var showYourName = false
    @State private var showNotifications = false
    @State private var showReminderStyle = false
    @State private var showQuietHours = false
    @State private var showAppIcon = false
    @State private var showTheme = false
    @State private var showTextSize = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var showPrivacy = false
    @State private var showTerms = false

    @State private var showDeleteAllConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleBlock

                SettingsProfileCard(
                    displayName: displayName,
                    totalStones: totalStonesPlaced,
                    onTap: { showProfile = true }
                )
                .padding(.horizontal, Spacing.xs)
                .padding(.top, Spacing.sm)

                habitsSection
                appearanceSection
                dataSection
                aboutSection

                footer
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        // Real screens (wired in request 1):
        .fullScreenCover(isPresented: $showNotifications) { NotificationsSettingsView() }
        .fullScreenCover(isPresented: $showReminderStyle) { ReminderStyleView() }
        .fullScreenCover(isPresented: $showQuietHours)    { QuietHoursView() }
        // Placeholders (real screens in next requests):
        .fullScreenCover(isPresented: $showProfile)   { placeholder(title: "Profile", icon: "person.fill") { showProfile = false } }
        .fullScreenCover(isPresented: $showAppIcon)   { placeholder(title: "App icon", icon: "app.badge") { showAppIcon = false } }
        .fullScreenCover(isPresented: $showTheme)     { placeholder(title: "Theme", icon: "moon.circle") { showTheme = false } }
        .fullScreenCover(isPresented: $showTextSize)  { placeholder(title: "Text size", icon: "textformat.size") { showTextSize = false } }
        .fullScreenCover(isPresented: $showExport)    { placeholder(title: "Export data", icon: "square.and.arrow.up") { showExport = false } }
        .fullScreenCover(isPresented: $showAbout)     { placeholder(title: "About Cairn", icon: "info.circle") { showAbout = false } }
        .fullScreenCover(isPresented: $showPrivacy)   { placeholder(title: "Privacy", icon: "lock.shield") { showPrivacy = false } }
        .fullScreenCover(isPresented: $showTerms)     { placeholder(title: "Terms", icon: "doc.text") { showTerms = false } }
        // Destructive confirm
        .cairnAlert(
            isPresented: $showDeleteAllConfirm,
            title: "Delete all data?",
            message: deleteAllMessage,
            confirmTitle: "Delete",
            confirmRole: .destructive,
            cancelTitle: "Cancel",
            onConfirm: { /* Real wipe lands in the data-management request */ }
        )
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Shape Cairn around")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
                Text("your")
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
                Text("life.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: Personal section
    // Comes right after the profile card — these two items (Why + Name) are
    // the cheapest, highest-impact retention hooks. A user with a written
    // "why" is anchored to the app. A user without one is renting.

    /// Short preview of the user's "why". Truncated to ~24 chars with ellipsis,
    /// or "Add yours" placeholder when empty.
    private var userWhyPreview: String {
        let trimmed = userWhy.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Add yours" }
        if trimmed.count <= 24 { return trimmed }
        return String(trimmed.prefix(24)) + "…"
    }

    private var displayNameValue: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Add yours" : trimmed
    }

    // MARK: Habits & Reminders

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "Habits & Reminders")
            groupedCard {
                SettingsRow(
                    icon: "bell",
                    label: "Notifications",
                    trailing: .navigation(value: notificationsEnabled ? "On" : "Off"),
                    action: { showNotifications = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "leaf",
                    label: "Reminder style",
                    trailing: .navigation(value: currentReminderStyleLabel),
                    action: { showReminderStyle = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "moon",
                    label: "Quiet hours",
                    trailing: .navigation(value: quietHoursValueString),
                    action: { showQuietHours = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "hand.tap",
                    label: "Haptic feedback",
                    trailing: .toggle(isOn: $hapticFeedbackEnabled)
                )
            }
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "Appearance")
            groupedCard {
                SettingsRow(
                    icon: "app.badge",
                    label: "App icon",
                    trailing: .navigation(value: appIconName),
                    action: { showAppIcon = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "moon.circle",
                    label: "Theme",
                    trailing: .navigation(value: currentThemeLabel),
                    action: { showTheme = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "textformat.size",
                    label: "Text size",
                    trailing: .navigation(value: currentTextSizeLabel),
                    action: { showTextSize = true }
                )
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "Data")
            groupedCard {
                SettingsRow(
                    icon: "square.and.arrow.up",
                    label: "Export data",
                    trailing: .navigation(value: nil),
                    action: { showExport = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "trash",
                    label: "Delete all data",
                    trailing: .navigation(value: nil),
                    isDestructive: true,
                    action: { showDeleteAllConfirm = true }
                )
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "About")
            groupedCard {
                SettingsRow(
                    icon: "info.circle",
                    label: "About Cairn",
                    trailing: .navigation(value: nil),
                    action: { showAbout = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "lock.shield",
                    label: "Privacy",
                    trailing: .navigation(value: nil),
                    action: { showPrivacy = true }
                )
                Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                SettingsRow(
                    icon: "doc.text",
                    label: "Terms",
                    trailing: .navigation(value: nil),
                    action: { showTerms = true }
                )
            }
        }
    }

    // MARK: Section container

    @ViewBuilder
    private func groupedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
        .padding(.horizontal, Spacing.xs)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Text("Made for ADHD brains, not against them.")
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Text("Version \(appVersion)")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: Derived

    private var totalStonesPlaced: Int {
        habits
            .filter { !$0.isArchived }
            .reduce(0) { acc, habit in
                acc + (habit.logs ?? []).filter { $0.modelContext != nil }.count
            }
    }

    private var currentReminderStyleLabel: String {
        (ReminderStyle(rawValue: reminderStyleRaw) ?? .gentle).label
    }

    private var quietHoursValueString: String {
        guard quietHoursEnabled else { return "Off" }
        return String(format: "%02d:00 — %02d:00", quietHoursStartHour, quietHoursEndHour)
    }

    private var currentThemeLabel: String {
        (ThemePreference(rawValue: themeRaw) ?? .system).label
    }

    private var currentTextSizeLabel: String {
        (TextSize(rawValue: textSizeRaw) ?? .standard).label
    }

    private var deleteAllMessage: String {
        let stoneCount = totalStonesPlaced
        let habitCount = habits.filter { !$0.isArchived }.count
        if habitCount == 0 && stoneCount == 0 {
            return "Cairn has no habits or stones yet. Nothing to remove."
        }
        let parts: String = {
            switch (habitCount, stoneCount) {
            case (1, 1): return "1 habit and its 1 stone"
            case (1, _): return "1 habit and its \(stoneCount) stones"
            case (_, 0): return "\(habitCount) habits"
            case (_, 1): return "\(habitCount) habits and 1 stone"
            default: return "\(habitCount) habits and \(stoneCount) stones"
            }
        }()
        return "All \(parts) will be removed. This can't be undone."
    }

    // MARK: Placeholder

    private func placeholder(title: String, icon: String, onDismiss: @escaping () -> Void) -> some View {
        SettingsPlaceholderScreen(
            title: title,
            icon: icon,
            message: "Coming in the next update.",
            onDismiss: onDismiss
        )
    }
}

// MARK: - Preference enums

enum ThemePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum TextSize: String, CaseIterable, Identifiable {
    case small, standard, large
    var id: String { rawValue }
    var label: String {
        switch self {
        case .small: return "Small"
        case .standard: return "Standard"
        case .large: return "Large"
        }
    }
}

// MARK: - Placeholder screen

struct SettingsPlaceholderScreen: View {
    let title: String
    let icon: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            content
            Spacer()
            Spacer()
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: onDismiss) {
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
            Text(title)
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    private var content: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Color.accentSage)
            Text(message)
                .font(.system(size: 15, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
    }
}
