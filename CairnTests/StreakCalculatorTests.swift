import Testing
import Foundation
@testable import Cairn

@Suite("StreakCalculator")
struct StreakCalculatorTests {

    private func makeHabit() -> Habit { Habit(name: "Test") }

    private func makeLog(habit: Habit, daysAgo: Int, hour: Int = 12) -> HabitLog {
        let cal = Calendar(identifier: .gregorian)
        let baseDay = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        let date = cal.date(bySettingHour: hour, minute: 0, second: 0, of: baseDay)!
        return HabitLog(habit: habit, loggedAt: date)
    }

    @Test("Lifetime stones never decreases")
    func lifetimeStones() {
        let h = makeHabit()
        let logs = [makeLog(habit: h, daysAgo: 0), makeLog(habit: h, daysAgo: 5), makeLog(habit: h, daysAgo: 30)]
        let calc = StreakCalculator()
        #expect(calc.lifetimeStones(logs) == 3)
    }

    @Test("Current run counts consecutive days back from today")
    func currentRunHappyPath() {
        let h = makeHabit()
        let logs = (0..<5).map { makeLog(habit: h, daysAgo: $0) }
        let calc = StreakCalculator()
        #expect(calc.currentRun(logs) == 5)
    }

    @Test("Current run survives 48h forgiveness window")
    func currentRunForgiveness() {
        let h = makeHabit()
        let logs = [makeLog(habit: h, daysAgo: 1), makeLog(habit: h, daysAgo: 2)]
        let calc = StreakCalculator()
        #expect(calc.currentRun(logs) >= 2)
    }

    @Test("Current run resets after >48h without a log")
    func currentRunResets() {
        let h = makeHabit()
        let logs = [makeLog(habit: h, daysAgo: 5), makeLog(habit: h, daysAgo: 6)]
        let calc = StreakCalculator()
        #expect(calc.currentRun(logs) == 0)
    }

    @Test("Longest run finds the max streak in history")
    func longestRunInHistory() {
        let h = makeHabit()
        let logs = [
            makeLog(habit: h, daysAgo: 0),
            makeLog(habit: h, daysAgo: 1),
            makeLog(habit: h, daysAgo: 10),
            makeLog(habit: h, daysAgo: 11),
            makeLog(habit: h, daysAgo: 12),
            makeLog(habit: h, daysAgo: 13)
        ]
        let calc = StreakCalculator()
        #expect(calc.longestRun(logs) == 4)
    }
}
