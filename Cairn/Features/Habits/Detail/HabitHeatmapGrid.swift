import SwiftUI
import SwiftData

/// Stone map for the Habit Info screen — a GitHub-style heatmap anchored at the
/// habit's creation day. The top-left square is day one; days fill **downward**
/// (7 per column) then wrap to the next column, so a brand-new habit shows a
/// single square and the map grows as days accrue. Caps at ~3 months; older
/// habits show a rolling window. Tap any square for that day's detail.
struct HabitHeatmapGrid: View {
    let habit: Habit

    private let maxDays = 91            // ~3 month ceiling
    private let rows = 7
    private let cellSize: CGFloat = 16
    private let cellSpacing: CGFloat = 4
    private let cornerRadius: CGFloat = 4

    private var cal: Calendar { Calendar.current }

    @State private var selectedDay: Date?

    var body: some View {
        let layout = computeLayout()

        VStack(alignment: .leading, spacing: Spacing.md) {
            header(layout: layout)
            grid(layout: layout)
            infoLine(layout: layout)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Layout

    private struct Layout {
        let firstDay: Date
        let today: Date
        let dayCount: Int          // days from firstDay…today, inclusive
        let columns: Int
        let logsByDay: [Date: Int]
        let target: Int
        let anchoredAtCreation: Bool
    }

    private func computeLayout() -> Layout {
        let today = cal.startOfDay(for: .now)
        let creationDay = cal.startOfDay(for: habit.createdAt)
        let cappedStart = cal.date(byAdding: .day, value: -(maxDays - 1), to: today) ?? today
        let anchoredAtCreation = creationDay >= cappedStart
        let firstDay = anchoredAtCreation ? creationDay : cappedStart
        let dayCount = max(1, (cal.dateComponents([.day], from: firstDay, to: today).day ?? 0) + 1)
        let columns = max(1, Int(ceil(Double(dayCount) / Double(rows))))

        return Layout(
            firstDay: firstDay,
            today: today,
            dayCount: dayCount,
            columns: columns,
            logsByDay: bucketLogs(),
            target: max(1, habit.targetPerDay),
            anchoredAtCreation: anchoredAtCreation
        )
    }

    // MARK: Header

    private func header(layout: Layout) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(layout.anchoredAtCreation ? "SINCE DAY ONE" : "LAST 3 MONTHS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
            Spacer()
            Text(layout.dayCount == 1 ? "Day 1" : "\(layout.dayCount) days")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
        }
    }

    // MARK: Grid (column-major, fills downward then wraps)

    private func grid(layout: Layout) -> some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(0..<layout.columns, id: \.self) { col in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        cell(col: col, row: row, layout: layout)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func cell(col: Int, row: Int, layout: Layout) -> some View {
        let index = col * rows + row
        if index < layout.dayCount {
            let date = cal.date(byAdding: .day, value: index, to: layout.firstDay) ?? layout.firstDay
            let count = layout.logsByDay[date] ?? 0
            let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: date) } ?? false

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill(count: count, target: layout.target))
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.textPrimary.opacity(isSelected ? 0.7 : 0), lineWidth: 1.5)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedDay = isSelected ? nil : date
                    }
                }
        } else {
            // Future cell in the last column — reserve space, stay invisible.
            Color.clear.frame(width: cellSize, height: cellSize)
        }
    }

    private func fill(count: Int, target: Int) -> Color {
        if count >= target { return Color.accentSage }
        if count > 0 { return Color.accentSage.opacity(0.42) }
        return Color.bgTertiary
    }

    // MARK: Info line (selected day, or legend)

    @ViewBuilder
    private func infoLine(layout: Layout) -> some View {
        if let day = selectedDay {
            let count = layout.logsByDay[cal.startOfDay(for: day)] ?? 0
            HStack(spacing: 6) {
                Text(dayLabel(day))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("·").foregroundStyle(Color.textTertiary)
                Text(count == 0 ? "no stones" : "\(count) \(count == 1 ? "stone" : "stones")")
                    .font(.system(size: 13))
                    .foregroundStyle(count == 0 ? Color.textTertiary : Color.accentSage)
                Spacer()
            }
            .padding(.top, 2)
        } else {
            legendRow
        }
    }

    private var legendRow: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
            legendSquare(Color.bgTertiary)
            legendSquare(Color.accentSage.opacity(0.42))
            legendSquare(Color.accentSage)
            Text("More")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
            Spacer()
            Text("Tap a square")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.top, 2)
    }

    private func legendSquare(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 12, height: 12)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    // MARK: Bucket

    private func bucketLogs() -> [Date: Int] {
        Dictionary(grouping: (habit.logs ?? []).filter { $0.modelContext != nil }) {
            cal.startOfDay(for: $0.loggedAt)
        }
        .mapValues { $0.count }
    }
}
