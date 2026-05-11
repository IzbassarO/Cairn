import SwiftUI
import SwiftData

struct CalendarMonthView: View {
    let logs: [HabitLog]
    let createdAt: Date

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)

    private var cal: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: Spacing.md) {
            header
            weekdayHeader
            daysGrid
        }
    }

    private var header: some View {
        HStack {
            navButton(systemImage: "chevron.left", disabled: !canGoBack) { advance(by: -1) }
            Spacer()
            VStack(spacing: 2) {
                Text(monthTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                Text(activeSummary)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .monospacedDigit()
            }
            Spacer()
            navButton(systemImage: "chevron.right", disabled: !canGoForward) { advance(by: 1) }
        }
    }

    private func navButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.bgTertiary))
        }
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1.0)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 6) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let cells = computeCells()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(cells) { cell in
                cellView(cell)
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: DayCell) -> some View {
        switch cell.kind {
        case .blank: Color.clear.aspectRatio(1, contentMode: .fit)
        case .day(let info): DayCellView(info: info)
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = cal.isDate(displayedMonth, equalTo: .now, toGranularity: .year) ? "MMMM" : "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var activeSummary: String {
        let count = logsInDisplayedMonth().filter { $0.value > 0 }.count
        return "\(count) active \(count == 1 ? "day" : "days")"
    }

    private var canGoBack: Bool { displayedMonth > cal.startOfMonth(for: createdAt) }
    private var canGoForward: Bool { displayedMonth < cal.startOfMonth(for: .now) }

    private func advance(by months: Int) {
        guard let next = cal.date(byAdding: .month, value: months, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            displayedMonth = cal.startOfMonth(for: next)
        }
    }

    private func computeCells() -> [DayCell] {
        let monthStart = cal.startOfMonth(for: displayedMonth)
        guard let monthInterval = cal.dateInterval(of: .month, for: monthStart) else { return [] }
        let monthEnd = monthInterval.end
        let today = cal.startOfDay(for: .now)
        let creationDay = cal.startOfDay(for: createdAt)
        let logsByDay = logsInDisplayedMonth()

        let weekday = cal.component(.weekday, from: monthStart)
        let daysBackToMonday = (weekday - 2 + 7) % 7
        guard let gridStart = cal.date(byAdding: .day, value: -daysBackToMonday, to: monthStart) else { return [] }

        var cells: [DayCell] = []
        var current = gridStart
        while (current < monthEnd || cells.count % 7 != 0) && cells.count < 42 {
            if current < monthStart || current >= monthEnd {
                cells.append(DayCell(kind: .blank))
            } else {
                let logCount = logsByDay[current] ?? 0
                let info = DayInfo(
                    date: current,
                    logCount: logCount,
                    isToday: cal.isDate(current, inSameDayAs: today),
                    isBeforeCreation: current < creationDay,
                    isFuture: current > today
                )
                cells.append(DayCell(kind: .day(info)))
            }
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
        }
        return cells
    }

    private func logsInDisplayedMonth() -> [Date: Int] {
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth) else { return [:] }
        return Dictionary(grouping: logs.filter {
            $0.modelContext != nil && interval.contains($0.loggedAt)
        }) {
            cal.startOfDay(for: $0.loggedAt)
        }.mapValues { $0.count }
    }
}

private struct DayInfo {
    let date: Date
    let logCount: Int
    let isToday: Bool
    let isBeforeCreation: Bool
    let isFuture: Bool
}

private struct DayCell: Identifiable {
    enum Kind { case blank; case day(DayInfo) }
    let id = UUID()
    let kind: Kind
}

private struct DayCellView: View {
    let info: DayInfo

    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: info.date)
    }

    var body: some View {
        ZStack {
            background
            if info.isToday {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.textPrimary, lineWidth: 1.6)
            }
            Text(dayNumber)
                .font(.system(size: 13, weight: textWeight, design: .rounded))
                .foregroundStyle(textColor)
                .monospacedDigit()
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(info.isBeforeCreation ? 0.30 : (info.isFuture ? 0.5 : 1.0))
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var background: some View {
        if info.logCount > 0 {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(fillStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                )
                .shadow(color: Color.accentSage.opacity(info.logCount > 1 ? 0.30 : 0.18),
                        radius: 2, y: 1)
        } else {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.bgTertiary)
        }
    }

    private var fillStyle: AnyShapeStyle {
        switch info.logCount {
        case 1:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentSage.opacity(0.55), Color.accentSage.opacity(0.72)],
                startPoint: .top, endPoint: .bottom))
        case 2:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentSage.opacity(0.78), Color.accentSage.opacity(0.95)],
                startPoint: .top, endPoint: .bottom))
        default:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentSage.opacity(0.92), Color.accentSage],
                startPoint: .top, endPoint: .bottom))
        }
    }

    private var textColor: Color {
        if info.logCount > 0 { return .white }
        if info.isToday { return Color.textPrimary }
        if info.isBeforeCreation || info.isFuture { return Color.textTertiary }
        return Color.textPrimary
    }

    private var textWeight: Font.Weight {
        info.logCount > 0 || info.isToday ? .semibold : .regular
    }

    private var accessibilityLabel: String {
        let f = DateFormatter(); f.dateStyle = .medium
        let date = f.string(from: info.date)
        if info.logCount > 0 {
            return "\(date), logged \(info.logCount) \(info.logCount == 1 ? "time" : "times")"
        }
        if info.isToday { return "\(date), today, no logs" }
        if info.isBeforeCreation { return "\(date), before habit started" }
        return date
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
