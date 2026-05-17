import SwiftUI

/// Month calendar grid. One circle per day of `month`.
///
/// Cell variants:
///  - **Future**: faint outline with greyed-out number (not interactive)
///  - **Today**: solid charcoal circle, white number, white dot indicator
///  - **Past with stones**: sage circle, intensity scaled to number of stones
///  - **Past without stones**: very light circle, greyed-out number
///  - **Selected (tapped)**: extra ring outline + slight scale
///
/// Leading offset before day 1: blank cells for the weekdays before the
/// month starts, respecting `Calendar.current.firstWeekday` (Sunday-start
/// in US, Monday-start in KZ / most of EU).
struct GardenCalendarGrid: View {
    /// Any date inside the displayed month — only month/year are used.
    let month: Date
    /// Daily stone counts: key is `Calendar.current.startOfDay(for:)` of each
    /// day in the month, value is number of stones placed that day.
    let stonesPerDay: [Date: Int]
    /// Currently selected day (drives bottom card). Nil = none selected.
    @Binding var selectedDay: Date?

    private var cal: Calendar { Calendar.current }

    /// "Highest stones placed in a single day this month". Drives the
    /// intensity scaling — a day with N stones is sage with opacity
    /// `0.25 + 0.75 * (N / maxStones)`. This way the calendar adapts: heavy
    /// users still see clear contrast, light users still see something other
    /// than uniformly pale circles.
    private var maxStonesInMonth: Int {
        max(stonesPerDay.values.max() ?? 0, 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            weekdayHeader
            daysGrid
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary.opacity(0.55))
        )
    }

    // MARK: Weekday header

    /// "S M T W T F S" (or "M T W T F S S" in Monday-start locales).
    /// Built from the user's calendar to respect their week-start preference.
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdayInitials, id: \.id) { item in
                Text(item.initial)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private struct WeekdayItem: Identifiable {
        let id: Int  // calendar weekday (1=Sun ... 7=Sat)
        let initial: String
    }

    /// Weekday initials rotated to start with `firstWeekday`.
    /// In en_US firstWeekday=1 → ["S","M","T","W","T","F","S"]
    /// In ru_KZ firstWeekday=2 → ["M","T","W","T","F","S","S"]
    private var orderedWeekdayInitials: [WeekdayItem] {
        let first = cal.firstWeekday  // 1..7
        let all = [
            WeekdayItem(id: 1, initial: "S"),
            WeekdayItem(id: 2, initial: "M"),
            WeekdayItem(id: 3, initial: "T"),
            WeekdayItem(id: 4, initial: "W"),
            WeekdayItem(id: 5, initial: "T"),
            WeekdayItem(id: 6, initial: "F"),
            WeekdayItem(id: 7, initial: "S"),
        ]
        // Rotate: first..7, then 1..first-1
        let rotated = all[(first - 1)...] + all[..<(first - 1)]
        return Array(rotated)
    }

    // MARK: Days grid

    private var daysGrid: some View {
        let info = monthInfo()
        let totalCells = info.leadingBlankCount + info.daysInMonth
        let rowCount = Int(ceil(Double(totalCells) / 7.0))

        return VStack(spacing: 10) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { col in
                        let cellIndex = row * 7 + col
                        let dayNumber = cellIndex - info.leadingBlankCount + 1
                        if dayNumber >= 1 && dayNumber <= info.daysInMonth {
                            dayCell(dayNumber: dayNumber, info: info)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            // Empty leading or trailing cell — keeps grid alignment.
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    // MARK: Day cell

    private struct MonthInfo {
        let monthStart: Date
        let daysInMonth: Int
        /// Number of blank cells before day 1 to align with `firstWeekday`.
        let leadingBlankCount: Int
    }

    private func monthInfo() -> MonthInfo {
        let comps = cal.dateComponents([.year, .month], from: month)
        let monthStart = cal.date(from: comps) ?? month
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        let weekdayOfFirst = cal.component(.weekday, from: monthStart) // 1..7
        // How far is that weekday from the calendar's firstWeekday?
        // e.g. firstWeekday=2 (Mon), weekdayOfFirst=6 (Fri) → 4 blank cells
        let blank = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        return MonthInfo(
            monthStart: monthStart,
            daysInMonth: daysInMonth,
            leadingBlankCount: blank
        )
    }

    @ViewBuilder
    private func dayCell(dayNumber: Int, info: MonthInfo) -> some View {
        let date = cal.date(byAdding: .day, value: dayNumber - 1, to: info.monthStart) ?? info.monthStart
        let stones = stonesPerDay[cal.startOfDay(for: date)] ?? 0
        let style = cellStyle(date: date, stones: stones)
        let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: date) } ?? false

        Button {
            // Only let the user select past/today cells.
            if !style.isFuture {
                if isSelected {
                    selectedDay = nil
                } else {
                    selectedDay = cal.startOfDay(for: date)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(style.fill)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.textPrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    // Selection ring sits outside the cell.
                    .padding(2)

                VStack(spacing: 1) {
                    Text("\(dayNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(style.numberColor)
                    if stones > 0 && !style.isToday {
                        dotIndicator(stones: stones, color: style.dotsColor)
                    } else if style.isToday {
                        dotIndicator(stones: max(stones, 1), color: .white)
                    }
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(style.isFuture)
    }

    /// Small dots showing stone count beneath the day number. 1-2 stones → that
    /// many dots. 3+ → three dots (ellipsis). Visual cue only — exact number
    /// is in the bottom card.
    private func dotIndicator(stones: Int, color: Color) -> some View {
        let count = min(stones, 3)
        return HStack(spacing: 2) {
            ForEach(0..<count, id: \.self) { _ in
                Circle().fill(color).frame(width: 3, height: 3)
            }
        }
    }

    // MARK: Cell styling

    private struct CellStyle {
        let fill: Color
        let numberColor: Color
        let dotsColor: Color
        let isFuture: Bool
        let isToday: Bool
    }

    private func cellStyle(date: Date, stones: Int) -> CellStyle {
        let today = cal.startOfDay(for: .now)
        let dayStart = cal.startOfDay(for: date)

        if dayStart > today {
            // Future: faint outline only
            return CellStyle(
                fill: Color.bgTertiary.opacity(0.35),
                numberColor: Color.textTertiary.opacity(0.7),
                dotsColor: .clear,
                isFuture: true,
                isToday: false
            )
        }

        if cal.isDate(dayStart, inSameDayAs: today) {
            // Today: solid charcoal
            return CellStyle(
                fill: Color.textPrimary,
                numberColor: .white,
                dotsColor: .white,
                isFuture: false,
                isToday: true
            )
        }

        // Past day. Intensity by stone count.
        if stones == 0 {
            return CellStyle(
                fill: Color.bgTertiary.opacity(0.55),
                numberColor: Color.textTertiary,
                dotsColor: .clear,
                isFuture: false,
                isToday: false
            )
        }

        // Stones present — sage with intensity scaling.
        let fraction = min(Double(stones) / Double(maxStonesInMonth), 1.0)
        // 1 stone → 0.32, max → 1.0
        let opacity = 0.32 + fraction * 0.68
        return CellStyle(
            fill: Color.accentSage.opacity(opacity),
            numberColor: .white,
            dotsColor: .white,
            isFuture: false,
            isToday: false
        )
    }
}
