import SwiftUI

struct ReminderSettingsView: View {
    @Binding var times: [Date]
    @Binding var schedule: HabitSchedule
    @Binding var customDays: Set<Int>

    var body: some View {
        Group {
            timesSection
            if !times.isEmpty {
                scheduleSection
            }
        }
    }

    private var timesSection: some View {
        Section {
            if times.isEmpty {
                Button { addTime() } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "bell.badge.plus")
                            .foregroundStyle(Color.accentSage)
                        Text("Add a reminder")
                            .foregroundStyle(Color.accentSage)
                            .fontWeight(.medium)
                    }
                }
            } else {
                ForEach(Array(times.indices), id: \.self) { index in
                    DatePicker(
                        "Time \(index + 1)",
                        selection: $times[index],
                        displayedComponents: .hourAndMinute
                    )
                }
                .onDelete { indices in
                    indices.sorted(by: >).forEach { times.remove(at: $0) }
                }

                Button { addTime() } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add another time")
                    }
                    .foregroundStyle(Color.accentSage)
                    .fontWeight(.medium)
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text(timesFooter).font(.system(size: 12))
        }
    }

    private var timesFooter: String {
        if times.isEmpty {
            return "No reminders. You can still log from the Today screen, widget, or watch."
        }
        if times.count == 1 {
            return "Swipe a time to delete it. Add as many times as you need (morning, afternoon, evening)."
        }
        return "We'll nudge you at each time on the days below."
    }

    private var scheduleSection: some View {
        Section {
            Picker("Repeat", selection: $schedule) {
                ForEach(HabitSchedule.allCases, id: \.self) { s in
                    Text(s.displayName).tag(s)
                }
            }
            if schedule == .custom {
                weekdayChips
                    .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.sm, trailing: Spacing.md))
            }
        } header: {
            Text("Days")
        } footer: {
            if schedule == .custom && customDays.isEmpty {
                Text("Pick at least one day, or switch to a preset.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentCoral)
            } else {
                Text(scheduleFooter).font(.system(size: 12))
            }
        }
    }

    private var scheduleFooter: String {
        switch schedule {
        case .daily: return "Reminders fire every day."
        case .weekdays: return "Monday through Friday only."
        case .weekends: return "Saturday and Sunday only."
        case .custom:
            let names = customDays.sorted(by: { sortKey($0) < sortKey($1) })
                .compactMap(longWeekdayName(_:)).joined(separator: ", ")
            return names.isEmpty ? "Pick at least one day." : "Reminders fire on \(names)."
        }
    }

    private var weekdayChips: some View {
        let order = [2, 3, 4, 5, 6, 7, 1]
        let symbols = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let weekday = order[i]
                let label = symbols[i]
                let selected = customDays.contains(weekday)
                Button {
                    if selected { customDays.remove(weekday) } else { customDays.insert(weekday) }
                } label: {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected ? .white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            Circle()
                                .fill(selected ? Color.accentSage : Color.bgTertiary)
                                .frame(width: 36, height: 36)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(longWeekdayName(weekday) ?? label)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func longWeekdayName(_ weekday: Int) -> String? {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard (1...7).contains(weekday) else { return nil }
        return names[weekday - 1]
    }

    private func sortKey(_ weekday: Int) -> Int { (weekday - 2 + 7) % 7 }

    private func addTime() {
        let cal = Calendar.current
        let baseTime = cal.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        if let last = times.sorted().last,
           let bumped = cal.date(byAdding: .hour, value: 4, to: last) {
            let comps = cal.dateComponents([.hour], from: bumped)
            times.append((comps.hour ?? 0) <= 22 ? bumped : baseTime)
        } else {
            times.append(baseTime)
        }
    }
}
