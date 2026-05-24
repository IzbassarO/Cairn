import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    enum AuthorizationState {
        case notDetermined
        case denied
        case authorized
    }

    func authorizationState() async -> AuthorizationState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("❌ Notification auth error: \(error)")
            return false
        }
    }

    func ensureAuthorizedThenSchedule(_ habit: Habit, settings: AppSettings? = nil) async {
        let state = await authorizationState()
        if state == .notDetermined {
            _ = await requestAuthorization()
        }
        guard await authorizationState() == .authorized else { return }
        await schedule(habit, settings: settings)
    }

    func schedule(_ habit: Habit, settings: AppSettings? = nil) async {
            cancel(habitId: habit.id)

            // Respect app-level notification state: master switch off or an
            // active timed pause means we schedule nothing. When the pause
            // ends / switch flips back on, a reschedule pass re-adds them.
            if let settings, !settings.notificationsActive() { return }

            guard !habit.notificationTimes.isEmpty else { return }

            let weekdays = habit.schedule.weekdays(custom: habit.customDays)
            guard !weekdays.isEmpty else { return }
            let isDaily = weekdays.count == 7

            // Tone-aware copy (falls back to neutral wording without settings).
            let title = settings?.notificationTitle(for: habit.name) ?? "Time for \(habit.name)"
            let body  = settings?.notificationBody(for: habit.name) ?? "Tap to log when you're ready."

            let center = UNUserNotificationCenter.current()
            for (timeIndex, time) in habit.notificationTimes.enumerated() {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                let weekdaysToSchedule: [Int] = isDaily ? [0] : Array(weekdays).sorted()

                for weekday in weekdaysToSchedule {
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default
                    content.interruptionLevel = habit.category == .meds ? .timeSensitive : .active
                    content.threadIdentifier = "habit_\(habit.id)"

                    var triggerComps = DateComponents()
                    triggerComps.hour = comps.hour
                    triggerComps.minute = comps.minute
                    if !isDaily { triggerComps.weekday = weekday }
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)

                    let id = identifier(habitId: habit.id, weekday: weekday, timeIndex: timeIndex)
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    do {
                        try await center.add(request)
                    } catch {
                        print("❌ Schedule failed for \(habit.name) wd=\(weekday) t=\(timeIndex): \(error)")
                    }
                }
            }
        }

    private func identifier(habitId: UUID, weekday: Int, timeIndex: Int) -> String {
        "habit_\(habitId)_\(weekday)_\(timeIndex)"
    }

    /// Re-evaluate every habit against the current app notification state.
    /// Call this when the pause is set, when it expires/resumes, when the
    /// master switch flips, or on app foreground. If notifications are off or
    /// paused, this cancels everything; otherwise it reschedules each habit.
    func rescheduleAll(_ habits: [Habit], settings: AppSettings) async {
        guard settings.notificationsActive() else {
            cancelAll()
            return
        }
        guard await authorizationState() == .authorized else { return }
        for habit in habits where !habit.isArchived {
            await schedule(habit, settings: settings)
        }
    }
    
    nonisolated func cancel(habitId: UUID) {
        let prefix = "habit_\(habitId)_"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    nonisolated func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
