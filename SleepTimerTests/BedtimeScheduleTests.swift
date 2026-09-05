import Foundation
import Testing
@testable import SleepTimer

struct BedtimeScheduleTests {
    private let calendar = SchedulerHarness.calendar

    private func date(day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    private var overnight: BedtimeSchedule {
        BedtimeSchedule(bedtime: TimeOfDay(hour: 22, minute: 0), wakeTime: TimeOfDay(hour: 6, minute: 0), calendar: calendar)
    }

    @Test func overnightWindowCrossesMidnight() {
        let window = overnight.window(startingOn: date(day: 4, hour: 12))
        #expect(window == DateInterval(start: date(day: 4, hour: 22), end: date(day: 5, hour: 6)))
    }

    @Test func sameDayWindowStaysOnOneDay() {
        let schedule = BedtimeSchedule(bedtime: TimeOfDay(hour: 13, minute: 0), wakeTime: TimeOfDay(hour: 15, minute: 0), calendar: calendar)
        let window = schedule.window(startingOn: date(day: 4, hour: 9))
        #expect(window == DateInterval(start: date(day: 4, hour: 13), end: date(day: 4, hour: 15)))
    }

    @Test func containingFindsYesterdaysWindowAfterMidnight() {
        let expected = DateInterval(start: date(day: 4, hour: 22), end: date(day: 5, hour: 6))
        #expect(overnight.window(containing: date(day: 4, hour: 22)) == expected)
        #expect(overnight.window(containing: date(day: 5, hour: 2)) == expected)
        #expect(overnight.window(containing: date(day: 5, hour: 5, minute: 59)) == expected)
    }

    @Test func containingIsHalfOpen() {
        #expect(overnight.window(containing: date(day: 5, hour: 6)) == nil)
        #expect(overnight.window(containing: date(day: 4, hour: 21, minute: 59)) == nil)
    }

    @Test func nextWindowIsTodayOrTomorrow() {
        #expect(overnight.nextWindow(startingAtOrAfter: date(day: 4, hour: 9))?.start == date(day: 4, hour: 22))
        #expect(overnight.nextWindow(startingAtOrAfter: date(day: 4, hour: 22))?.start == date(day: 4, hour: 22))
        #expect(overnight.nextWindow(startingAtOrAfter: date(day: 4, hour: 23))?.start == date(day: 5, hour: 22))
    }
}
