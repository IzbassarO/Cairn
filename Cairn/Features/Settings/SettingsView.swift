import SwiftUI
import SwiftData

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

    // MARK: - Navigation state
    @State private var showProfile = false
    @State private var showYourWhy = false
    @State private var showYourName = false
    @State private var showNotifications = false
    @State private var showReminderStyle = false
    @State private var showQuietHours = false
    @State private var showAppearance = false
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
        .slideCover(isPresented: $showNotifications) { NotificationsSettingsView(onClose: { showNotifications = false }) }
        .slideCover(isPresented: $showReminderStyle) { ReminderStyleView(onClose: { showReminderStyle = false }) }
        .sheet(isPresented: $showQuietHours)         { QuietHoursSheet() }
        // Placeholders (real screens in next requests):
        .slideCover(isPresented: $showProfile)   { ProfileView(onDismiss: { showProfile = false }) }
        .slideCover(isPresented: $showYourWhy)   { placeholder(title: "Your why", icon: "quote.opening") { showYourWhy = false } }
        .slideCover(isPresented: $showYourName)  { placeholder(title: "Your name", icon: "person") { showYourName = false } }
        .slideCover(isPresented: $showAppearance) { AppearanceView(onClose: { showAppearance = false }) }
        .slideCover(isPresented: $showExport)    { ExportDataView(onClose: { showExport = false }) }
        .slideCover(isPresented: $showAbout)     { AboutView(onClose: { showAbout = false }) }
        .slideCover(isPresented: $showPrivacy)   { PrivacyView(onClose: { showPrivacy = false }) }
        .slideCover(isPresented: $showTerms)     { TermsView(onClose: { showTerms = false }) }
        .sheet(isPresented: $showDeleteAllConfirm) {
            DeleteAllDataSheet(onExportRequest: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showExport = true
                }
            })
        }
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
                    icon: "paintbrush",
                    label: "Appearance",
                    trailing: .navigation(value: appearanceSummary),
                    action: { showAppearance = true }
                )
            }
        }
    }

    private var appearanceSummary: String {
        currentThemeLabel
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
