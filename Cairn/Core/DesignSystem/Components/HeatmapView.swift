import SwiftUI
import SwiftData

struct HeatmapView: View {
    let logs: [HabitLog]
    var weekCount: Int = 12

    private let cellSpacing: CGFloat = 4
    private let cornerRadius: CGFloat = 5
    private let labelWidth: CGFloat = 16
    private let labelGap: CGFloat = 8

    // Force Monday-first regardless of locale (GitHub-style, familiar).
    private let mondayWeekday: Int = 2  // iOS Calendar: 1=Sun, 2=Mon, ..., 7=Sat

    private var cal: Calendar { Calendar.current }

    var body: some View {
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today)
        let daysBackToMonday = (weekday - mondayWeekday + 7) % 7
        let currentWeekStart = cal.date(byAdding: .day, value: -daysBackToMonday, to: today) ?? today
        let gridStart = cal.date(byAdding: .day, value: -(weekCount - 1) * 7, to: currentWeekStart) ?? today

        let logsByDay = bucket()
        let activeDays = logsByDay.values.filter { $0 > 0 }.count

        VStack(alignment: .leading, spacing: Spacing.sm) {
            header(activeDays: activeDays)
            grid(gridStart: gridStart, today: today, logsByDay: logsByDay)
            legend
        }
    }

    private func header(activeDays: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("12-week activity")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
            Text("\(activeDays) active \(activeDays == 1 ? "day" : "days")")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .monospacedDigit()
        }
    }

    private func grid(gridStart: Date, today: Date, logsByDay: [Date: Int]) -> some View {
        // Row-major layout: each row = [weekday label, 12 cells].
        // Cells use aspectRatio(1) inside an HStack so the row fills full width.
        VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: labelGap) {
                    Text(weekdayLabel(row))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: labelWidth, alignment: .trailing)
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<weekCount, id: \.self) { week in
                            cell(week: week, row: row, gridStart: gridStart, today: today, logsByDay: logsByDay)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(week: Int, row: Int, gridStart: Date, today: Date, logsByDay: [Date: Int]) -> some View {
        let offset = week * 7 + row
        let date = cal.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
        let count = logsByDay[date] ?? 0
        let isFuture = date > today
        let isToday = cal.isDate(date, inSameDayAs: today)

        if isFuture {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillStyle(for: count))
                .overlay {
                    if count > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                    }
                }
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.textPrimary, lineWidth: 1.8)
                    }
                }
                .shadow(
                    color: isToday
                        ? Color.accentSage.opacity(0.55)
                        : (count > 1 ? Color.accentSage.opacity(0.30) : .clear),
                    radius: isToday ? 3 : 1.5,
                    y: isToday ? 0 : 0.5
                )
        }
    }

    private var legend: some View {
        HStack {
            Spacer()
            HStack(spacing: 5) {
                Text("less")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
                ForEach([0, 1, 2, 3], id: \.self) { count in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(fillStyle(for: count))
                        .frame(width: 9, height: 9)
                }
                Text("more")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.top, 2)
    }

    private func fillStyle(for count: Int) -> AnyShapeStyle {
        switch count {
        case 0:
            return AnyShapeStyle(Color.bgTertiary)
        case 1:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentSage.opacity(0.32), Color.accentSage.opacity(0.45)],
                startPoint: .top, endPoint: .bottom))
        case 2:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentSage.opacity(0.58), Color.accentSage.opacity(0.78)],
                startPoint: .top, endPoint: .bottom))
        default:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.accentSage.opacity(0.92), Color.accentSage],
                startPoint: .top, endPoint: .bottom))
        }
    }

    private func weekdayLabel(_ row: Int) -> String {
        // Monday-first: row 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun.
        switch row {
        case 0: return "M"
        case 2: return "W"
        case 4: return "F"
        default: return ""
        }
    }

    private func bucket() -> [Date: Int] {
        Dictionary(grouping: logs.filter { $0.modelContext != nil }) {
            cal.startOfDay(for: $0.loggedAt)
        }
        .mapValues { $0.count }
    }
}
