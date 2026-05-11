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

    func ensureAuthorizedThenSchedule(_ habit: Habit) async {
        let state = await authorizationState()
        if state == .notDetermined {
            _ = await requestAuthorization()
        }
        guard await authorizationState() == .authorized else { return }
        await schedule(habit)
    }

    func schedule(_ habit: Habit) async {
            cancel(habitId: habit.id)
            guard !habit.notificationTimes.isEmpty else { return }

            let weekdays = habit.schedule.weekdays(custom: habit.customDays)
            guard !weekdays.isEmpty else { return }
            let isDaily = weekdays.count == 7

            let center = UNUserNotificationCenter.current()
            for (timeIndex, time) in habit.notificationTimes.enumerated() {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                let weekdaysToSchedule: [Int] = isDaily ? [0] : Array(weekdays).sorted()

                for weekday in weekdaysToSchedule {
                    let content = UNMutableNotificationContent()
                    content.title = "Time for \(habit.name)"
                    content.body = "Tap to log when you're ready."
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
