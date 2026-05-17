import SwiftUI
import SwiftData

/// 12-week heatmap for the Habit Info screen. Visual model:
///  - "LAST 3 MONTHS" eyebrow
///  - 7 rows × 12 cols (Mon..Sun rows, oldest..newest weeks as columns)
///  - Top-left cell = Monday of the earliest week in the window. Cells before
///    `habit.createdAt` are rendered at lowest opacity, so the user sees
///    "this habit didn't exist yet" rather than "missed".
///  - Date range "Mar 1 ... May 17" at the bottom corners
///  - Two intensity levels per cell:
///     - `partial` (sage low): logged at least once that day
///     - `full` (sage strong): reached `targetPerDay` that day
struct HabitHeatmapGrid: View {
    let habit: Habit

    private let weekCount: Int = 12
    private let cellSpacing: CGFloat = 3
    private let cornerRadius: CGFloat = 4

    private var cal: Calendar { Calendar.current }

    var body: some View {
        let layout = computeLayout()

        VStack(alignment: .leading, spacing: Spacing.md) {
            header

            grid(
                gridStart: layout.gridStart,
                today: layout.today,
                creationDay: layout.creationDay,
                logsByDay: layout.logsByDay,
                target: layout.target
            )

            dateRange(gridStart: layout.gridStart, today: layout.today)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Layout precomputation
    // Done outside of @ViewBuilder so the body stays a clean View expression.

    private struct Layout {
        let today: Date
        let gridStart: Date
        let creationDay: Date
        let logsByDay: [Date: Int]
        let target: Int
    }

    private func computeLayout() -> Layout {
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today)
        // 1=Sun … 7=Sat. Make Monday=2 the row-zero anchor.
        let daysBackToMonday = (weekday - 2 + 7) % 7
        let currentWeekStart = cal.date(byAdding: .day, value: -daysBackToMonday, to: today) ?? today
        let gridStart = cal.date(byAdding: .day, value: -(weekCount - 1) * 7, to: currentWeekStart) ?? today

        return Layout(
            today: today,
            gridStart: gridStart,
            creationDay: cal.startOfDay(for: habit.createdAt),
            logsByDay: bucketLogs(),
            target: max(1, habit.targetPerDay)
        )
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("LAST 3 MONTHS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)
            Spacer()
        }
    }

    // MARK: Grid (7 rows × 12 cols)

    private func grid(
        gridStart: Date,
        today: Date,
        creationDay: Date,
        logsByDay: [Date: Int],
        target: Int
    ) -> some View {
        // We render row-major because rows = weekdays (Mon at row 0 on top).
        VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<weekCount, id: \.self) { week in
                        cell(
                            week: week,
                            row: row,
                            gridStart: gridStart,
                            today: today,
                            creationDay: creationDay,
                            logsByDay: logsByDay,
                            target: target
                        )
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(
        week: Int,
        row: Int,
        gridStart: Date,
        today: Date,
        creationDay: Date,
        logsByDay: [Date: Int],
        target: Int
    ) -> some View {
        let level = cellLevel(
            week: week,
            row: row,
            gridStart: gridStart,
            today: today,
            creationDay: creationDay,
            logsByDay: logsByDay,
            target: target
        )

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(level.fill)
    }

    /// Pure helper — no SwiftUI involved. Kept separate from `cell(...)` so the
    /// `@ViewBuilder` doesn't try to interpret the if/else chain as views.
    private func cellLevel(
        week: Int,
        row: Int,
        gridStart: Date,
        today: Date,
        creationDay: Date,
        logsByDay: [Date: Int],
        target: Int
    ) -> CellLevel {
        let offset = week * 7 + row
        let date = cal.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
        let count = logsByDay[date] ?? 0

        if date > today {
            return .future
        }
        if date < creationDay {
            return .beforeCreation
        }
        if count >= target {
            return .full
        }
        if count > 0 {
            return .partial
        }
        return .empty
    }

    // MARK: Date range

    private func dateRange(gridStart: Date, today: Date) -> some View {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return HStack {
            Text(f.string(from: gridStart))
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
            Spacer()
            Text(f.string(from: today))
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.top, 4)
    }

    // MARK: Cell levels

    private enum CellLevel {
        case future          // not rendered (clear)
        case beforeCreation  // habit didn't exist yet — very faint bg
        case empty           // no log, but habit existed — faint bg
        case partial         // logged at least once
        case full            // reached targetPerDay

        var fill: AnyShapeStyle {
            switch self {
            case .future:
                return AnyShapeStyle(Color.clear)
            case .beforeCreation:
                return AnyShapeStyle(Color.bgTertiary.opacity(0.45))
            case .empty:
                return AnyShapeStyle(Color.bgTertiary)
            case .partial:
                return AnyShapeStyle(Color.accentSage.opacity(0.42))
            case .full:
                return AnyShapeStyle(Color.accentSage)
            }
        }
    }

    // MARK: Bucket

    private func bucketLogs() -> [Date: Int] {
        Dictionary(grouping: (habit.logs ?? []).filter { $0.modelContext != nil }) {
            cal.startOfDay(for: $0.loggedAt)
        }
        .mapValues { $0.count }
    }
}
