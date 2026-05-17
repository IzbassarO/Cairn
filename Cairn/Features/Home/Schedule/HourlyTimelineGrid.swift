import SwiftUI

/// Apple Calendar Day-view-style timeline.
///
/// Layout:
///  - Left rail: hour labels (06, 08, 10, ...) every 2 hours, vertically
///  - Main area: hourly horizontal lines + habit cards positioned by reminder
///  - Optional current-time indicator drawn over the grid (only when showing
///    today)
///
/// Cards are laid out absolutely. Overlapping cards (same hour, different
/// minutes within ~25min) stack vertically with a tiny y-offset to stay readable.
struct HourlyTimelineGrid: View {
    /// Cards to lay out. Each carries its own reminder time and visual state.
    let entries: [TimelineEntry]
    /// True when the grid represents today — draws the current-time indicator
    /// and auto-scrolls to it on appear.
    var showsCurrentTime: Bool = true

    // MARK: Layout

    /// Hour bounds: clamp to 5am ... 11pm by default. If the user has reminders
    /// outside this range, the grid expands to include them.
    private var hourBounds: (start: Int, end: Int) {
        let defaultStart = 5
        let defaultEnd = 23

        let cal = Calendar.current
        let hours = entries.map { cal.component(.hour, from: $0.reminderTime) }
        let minEntry = hours.min() ?? defaultStart
        let maxEntry = hours.max() ?? defaultEnd

        return (
            min(defaultStart, minEntry),
            max(defaultEnd, maxEntry + 1)  // +1 so the last card has room
        )
    }

    /// Pixels per hour. ~64 gives readable density on iPhone 14/15 viewport.
    private let hourHeight: CGFloat = 64
    /// Width of the left hour-label rail.
    private let railWidth: CGFloat = 44

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    grid
                    cards
                    if showsCurrentTime {
                        currentTimeIndicator
                    }
                }
                .frame(height: totalHeight)
                .padding(.vertical, Spacing.md)
            }
            .onAppear {
                // Scroll so "now" is roughly 1/3 from top.
                if showsCurrentTime {
                    let scrollAnchor = currentScrollAnchorID()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            proxy.scrollTo(scrollAnchor, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var totalHeight: CGFloat {
        let hours = hourBounds.end - hourBounds.start
        return CGFloat(hours) * hourHeight
    }

    // MARK: Grid (hour rows + labels)

    private var grid: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(hourBounds.start..<hourBounds.end, id: \.self) { hour in
                hourRow(hour: hour)
                    .frame(height: hourHeight)
                    .id("hour-\(hour)")
            }
        }
    }

    private func hourRow(hour: Int) -> some View {
        // Show label every 2 hours (06, 08, 10, ...) to avoid clutter.
        let showLabel = hour % 2 == 0
        return HStack(alignment: .top, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if showLabel {
                    Text(String(format: "%02d", hour))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.textTertiary)
                        .padding(.top, -6)
                }
            }
            .frame(width: railWidth, alignment: .leading)

            // Hairline divider at the top of each hour row.
            Rectangle()
                .fill(Color.bgTertiary.opacity(0.7))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, 0)
            Spacer(minLength: 0)
        }
    }

    // MARK: Cards (positioned absolutely)

    private var cards: some View {
        ForEach(positionedCards, id: \.entry.id) { positioned in
            ScheduleHabitCard(
                habit: positioned.entry.habit,
                reminderTime: positioned.entry.reminderTime,
                state: positioned.entry.state
            )
            .frame(maxWidth: cardMaxWidth)
            .offset(x: railWidth + 4, y: positioned.yOffset)
        }
    }

    /// Card width: total available minus left rail minus right padding.
    /// Computed lazily by GeometryReader, but using a fixed reasonable default.
    private var cardMaxWidth: CGFloat {
        UIScreen.main.bounds.width - railWidth - Spacing.md * 2 - 12
    }

    /// Layout cards by reminder time. Overlap handling: if two cards would
    /// land within ~25 vertical points of each other, the second card is
    /// shifted down by `cardHeight + 4`. Simple but works for normal-sized
    /// schedules (3-7 habits/day). For dense schedules we'd want column
    /// splitting, but that's overkill in v1.0.
    private struct PositionedCard {
        let entry: TimelineEntry
        let yOffset: CGFloat
    }

    private let approxCardHeight: CGFloat = 48
    private let overlapThreshold: CGFloat = 25

    private var positionedCards: [PositionedCard] {
        let cal = Calendar.current
        let sorted = entries.sorted { $0.reminderTime < $1.reminderTime }

        var result: [PositionedCard] = []
        for entry in sorted {
            let hour = cal.component(.hour, from: entry.reminderTime)
            let minute = cal.component(.minute, from: entry.reminderTime)
            let hoursFromStart = CGFloat(hour - hourBounds.start)
            let minuteFraction = CGFloat(minute) / 60.0
            var y = (hoursFromStart + minuteFraction) * hourHeight

            // If this y is too close to the last placed card, push it down.
            if let last = result.last, y - last.yOffset < overlapThreshold {
                y = last.yOffset + approxCardHeight + 4
            }

            result.append(PositionedCard(entry: entry, yOffset: y))
        }
        return result
    }

    // MARK: Current-time indicator

    @ViewBuilder
    private var currentTimeIndicator: some View {
        let cal = Calendar.current
        let now = Date.now
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        if hour >= hourBounds.start && hour < hourBounds.end {
            let y = (CGFloat(hour - hourBounds.start) + CGFloat(minute) / 60.0) * hourHeight
            HStack(spacing: 0) {
                Circle()
                    .fill(Color.accentCoral)
                    .frame(width: 8, height: 8)
                    .offset(x: railWidth - 4)
                Rectangle()
                    .fill(Color.accentCoral)
                    .frame(height: 1.5)
            }
            .offset(y: y - 4)
        }
    }

    /// ID of the hour row to scroll to on appear. Pick the hour just before
    /// current so "now" is roughly centered.
    private func currentScrollAnchorID() -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: .now)
        let target = max(hourBounds.start, hour - 1)
        return "hour-\(target)"
    }
}

/// One entry on the timeline.
struct TimelineEntry: Identifiable {
    let id = UUID()
    let habit: Habit
    let reminderTime: Date
    let state: ScheduleHabitCard.State
}
