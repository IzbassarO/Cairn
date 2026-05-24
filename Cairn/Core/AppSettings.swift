import SwiftUI
import Combine

// MARK: - AppSettings
//
// Single source of truth for everything under Settings. Views should ask
// AppSettings *behavioral questions* ("can a notification fire now?",
// "is this time inside quiet hours?") rather than reading raw @AppStorage
// keys scattered across the app.
//
// Why this exists:
//  - Cascading rules: one setting (quiet hours, pause, reminder style) needs
//    to affect many screens. Centralizing the logic keeps it consistent.
//  - One place to evolve: when new settings land, behavior lives here instead
//    of being duplicated across screens.
//
// Inject once at the app root:
//   @StateObject private var settings = AppSettings()
//   RootView().environmentObject(settings)
//
// Read anywhere:
//   @EnvironmentObject private var settings: AppSettings

@MainActor
final class AppSettings: ObservableObject {

    // MARK: Backing store
    //
    // We keep UserDefaults as the persistence layer (same keys the app already
    // uses, so nothing migrates), but expose them through published computed
    // wrappers so SwiftUI updates and behavioral methods both flow through here.

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.notificationsEnabled: true,
            Keys.reminderStyle: ReminderStyle.gentle.rawValue,
            Keys.quietHoursEnabled: true,
            Keys.quietHoursStartHour: 22,
            Keys.quietHoursEndHour: 7,
            Keys.hapticFeedbackEnabled: true,
            Keys.theme: ThemePreference.system.rawValue,
            Keys.textSize: TextSize.standard.rawValue
        ])
    }

    private enum Keys {
        static let notificationsEnabled   = "notificationsEnabled"
        static let notificationsPausedUntil = "notificationsPausedUntil" // Double (timeIntervalSince1970), 0 = no pause
        static let reminderStyle          = "reminderStyle"
        static let quietHoursEnabled      = "quietHoursEnabled"
        static let quietHoursStartHour    = "quietHoursStartHour"
        static let quietHoursEndHour      = "quietHoursEndHour"
        static let hapticFeedbackEnabled  = "hapticFeedbackEnabled"
        static let theme                  = "themePreference"
        static let textSize               = "textSize"
    }

    // MARK: - Notifications

    /// Master switch. When false, no notifications fire (indefinitely).
    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Keys.notificationsEnabled) }
        set { objectWillChange.send(); defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    /// The moment notifications resume after a timed pause. `nil` = not paused.
    /// Stored as an absolute Date so the pause survives app relaunch and ticks
    /// in real time.
    var notificationsPausedUntil: Date? {
        get {
            let t = defaults.double(forKey: Keys.notificationsPausedUntil)
            guard t > 0 else { return nil }
            let date = Date(timeIntervalSince1970: t)
            return date > Date() ? date : nil  // expired pauses read as nil
        }
        set {
            objectWillChange.send()
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Keys.notificationsPausedUntil)
        }
    }

    /// True while a timed pause is currently active.
    var isNotificationsPaused: Bool { notificationsPausedUntil != nil }

    /// THE question the rest of the app asks. Notifications are live only when
    /// the master switch is on AND there's no active pause.
    func notificationsActive(at date: Date = Date()) -> Bool {
        guard notificationsEnabled else { return false }
        if let until = notificationsPausedUntil, date < until { return false }
        return true
    }

    /// Pause notifications for a preset duration (real-time, survives relaunch).
    func pauseNotifications(_ preset: NotificationPause) {
        notificationsPausedUntil = preset.endDate(from: Date())
    }

    /// Clear an active timed pause (notifications resume immediately, subject
    /// to the master switch).
    func resumeNotifications() {
        notificationsPausedUntil = nil
    }

    // MARK: - Reminder style

    var reminderStyle: ReminderStyle {
        get { ReminderStyle(rawValue: defaults.string(forKey: Keys.reminderStyle) ?? "") ?? .gentle }
        set { objectWillChange.send(); defaults.set(newValue.rawValue, forKey: Keys.reminderStyle) }
    }

    /// Notification copy for a habit, honoring the chosen tone. NotificationService
    /// should use this instead of hardcoding strings.
    func notificationTitle(for habitName: String) -> String {
        switch reminderStyle {
        case .gentle:   return habitName
        case .standard: return "Time for \(habitName)"
        case .bold:     return "\(habitName) — now."
        }
    }

    func notificationBody(for habitName: String) -> String {
        switch reminderStyle {
        case .gentle:   return "When you're ready — \(habitName.lowercased()) is waiting."
        case .standard: return "Tap to log when you're ready."
        case .bold:     return "Do it now. Future-you will thank you."
        }
    }

    // MARK: - Quiet hours

    var quietHoursEnabled: Bool {
        get { defaults.bool(forKey: Keys.quietHoursEnabled) }
        set { objectWillChange.send(); defaults.set(newValue, forKey: Keys.quietHoursEnabled) }
    }

    var quietHoursStartHour: Int {
        get { defaults.integer(forKey: Keys.quietHoursStartHour) }
        set { objectWillChange.send(); defaults.set(newValue, forKey: Keys.quietHoursStartHour) }
    }

    var quietHoursEndHour: Int {
        get { defaults.integer(forKey: Keys.quietHoursEndHour) }
        set { objectWillChange.send(); defaults.set(newValue, forKey: Keys.quietHoursEndHour) }
    }

    /// THE question habit-creation screens ask before accepting a reminder time.
    /// Handles overnight windows (e.g. 22:00 → 07:00 wraps past midnight).
    func isWithinQuietHours(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = calendar.component(.hour, from: date)
        let start = quietHoursStartHour
        let end = quietHoursEndHour
        if start == end { return false }
        if start < end {
            return hour >= start && hour < end          // same-day window
        } else {
            return hour >= start || hour < end          // overnight window
        }
    }

    /// Convenience for UI warnings ("this lands during your rest time").
    func quietHoursWarning(for date: Date) -> String? {
        guard isWithinQuietHours(date) else { return nil }
        return "This reminder lands during your quiet hours. You can still set it, but it may interrupt your rest."
    }

    // MARK: - Haptics

    var hapticFeedbackEnabled: Bool {
        get { defaults.bool(forKey: Keys.hapticFeedbackEnabled) }
        set { objectWillChange.send(); defaults.set(newValue, forKey: Keys.hapticFeedbackEnabled) }
    }

    // MARK: - Appearance

    var theme: ThemePreference {
        get { ThemePreference(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system }
        set { objectWillChange.send(); defaults.set(newValue.rawValue, forKey: Keys.theme) }
    }

    var textSize: TextSize {
        get { TextSize(rawValue: defaults.string(forKey: Keys.textSize) ?? "") ?? .standard }
        set { objectWillChange.send(); defaults.set(newValue.rawValue, forKey: Keys.textSize) }
    }
}

// MARK: - Notification pause presets

/// Human-readable pause durations. Chosen for fast scanning (ADHD-friendly):
/// whole-unit labels read quicker than "30d".
enum NotificationPause: String, CaseIterable, Identifiable {
    case hour, day, week, month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hour:  return "1 hour"
        case .day:   return "1 day"
        case .week:  return "1 week"
        case .month: return "1 month"
        }
    }

    /// Short label for compact chips.
    var shortLabel: String {
        switch self {
        case .hour:  return "1h"
        case .day:   return "1d"
        case .week:  return "1w"
        case .month: return "1mo"
        }
    }

    func endDate(from start: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .hour:  return calendar.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)
        case .day:   return calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        case .week:  return calendar.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(604800)
        case .month: return calendar.date(byAdding: .month, value: 1, to: start) ?? start.addingTimeInterval(2592000)
        }
    }
}

// MARK: - Quiet hours presets

/// Time-of-day windows for the quiet-hours dial. Each preset just sets the
/// start/end hours; the dial reflects the same values. Kept consistent with the
/// dial's axis (time of day) rather than mixing in day-of-week rules.
enum QuietHoursPreset: String, CaseIterable, Identifiable {
    case night, morning, evening, workday

    var id: String { rawValue }

    var label: String {
        switch self {
        case .night:   return "Night"
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .workday: return "Workday"
        }
    }

    /// (startHour, endHour) in 24h. End may be ≤ start to mean an overnight wrap.
    var range: (start: Int, end: Int) {
        switch self {
        case .night:   return (22, 7)   // 22:00 → 07:00
        case .morning: return (6, 9)    // early focus block
        case .evening: return (18, 22)  // wind-down
        case .workday: return (9, 17)   // deep-work hours
        }
    }

    /// Short "22 — 07" style summary for the chip.
    var summary: String {
        String(format: "%02d — %02d", range.start, range.end)
    }

    /// True when the given hours match this preset exactly.
    func matches(start: Int, end: Int) -> Bool {
        range.start == start && range.end == end
    }
}
