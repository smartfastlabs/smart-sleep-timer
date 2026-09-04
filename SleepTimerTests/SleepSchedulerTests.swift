import Foundation
import Testing
@testable import SleepTimer

/// Drives a `SleepScheduler` with a fake clock, idle timer, and sleep call recorder.
@MainActor
private final class Harness {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    var now: Date
    var idleSeconds: TimeInterval = 600
    private(set) var sleepRequests = 0

    let preferences: Preferences
    private(set) var scheduler: SleepScheduler!

    init(now: Date, bedtime: TimeOfDay? = nil) {
        self.now = now
        let defaults = UserDefaults(suiteName: "SleepSchedulerTests.\(UUID().uuidString)")!
        preferences = Preferences(defaults: defaults)
        if let bedtime {
            preferences.bedtime = bedtime
            preferences.bedtimeEnabled = true
        }
        scheduler = SleepScheduler(
            preferences: preferences,
            calendar: Self.calendar,
            clock: { [unowned self] in self.now },
            sleeper: Sleeper(harness: self),
            activity: Activity(harness: self)
        )
    }

    /// Moves the clock forward and ticks once, as the app would after that much time.
    func advance(seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
        scheduler.tick()
    }

    func date(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        Self.calendar.date(bySettingHour: hour, minute: minute, second: second, of: now)!
    }

    private struct Sleeper: SystemSleeping {
        unowned let harness: Harness
        func sleep() { harness.sleepRequests += 1 }
    }

    private struct Activity: ActivityMonitoring {
        unowned let harness: Harness
        func secondsSinceLastInput() -> TimeInterval { harness.idleSeconds }
    }
}

@MainActor
struct SleepSchedulerTests {
    /// A weekday evening at 9:00 PM Pacific.
    private static let evening = Harness.calendar.date(
        from: DateComponents(year: 2026, month: 9, day: 4, hour: 21)
    )!

    @Test func timerCountsDownAndSleepsWhenIdle() {
        let harness = Harness(now: Self.evening)
        harness.scheduler.startTimer(minutes: 5)

        #expect(harness.scheduler.nextSleepTime == Self.evening.addingTimeInterval(300))
        #expect(harness.preferences.sleepIntervalMinutes == 5)

        harness.advance(seconds: 299)
        #expect(harness.sleepRequests == 0)

        harness.advance(seconds: 2)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.timerEnd == nil)
    }

    @Test func timerSkipsSleepWhileUserIsActive() {
        let harness = Harness(now: Self.evening)
        harness.idleSeconds = 10
        harness.scheduler.startTimer(minutes: 1)

        harness.advance(seconds: 61)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.timerEnd == nil)
    }

    @Test func systemWakeCountsAsActivity() {
        let harness = Harness(now: Self.evening)
        harness.scheduler.startTimer(minutes: 1)
        harness.now = harness.now.addingTimeInterval(55)
        harness.scheduler.noteWake()

        harness.advance(seconds: 6)
        #expect(harness.sleepRequests == 0)
    }

    @Test func zeroMinutesCancelsTimer() {
        let harness = Harness(now: Self.evening)
        harness.scheduler.startTimer(minutes: 30)
        harness.scheduler.startTimer(minutes: 0)

        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(harness.preferences.sleepIntervalMinutes == 0)
    }

    @Test func extendingTimerKeepsQuickPick() {
        let harness = Harness(now: Self.evening)
        harness.scheduler.startTimer(minutes: 30)
        harness.scheduler.extendTimer(minutes: 10)

        #expect(harness.scheduler.timerEnd == Self.evening.addingTimeInterval(600))
        #expect(harness.preferences.sleepIntervalMinutes == 30)
    }

    @Test func bedtimeFiresOnce() {
        let harness = Harness(now: Self.evening, bedtime: TimeOfDay(hour: 22, minute: 0))
        #expect(harness.scheduler.nextSleepTime == harness.date(hour: 22))

        harness.advance(seconds: 59 * 60)
        #expect(harness.sleepRequests == 0)

        harness.advance(seconds: 61)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.nextSleepTime == nil)

        harness.advance(seconds: 600)
        #expect(harness.sleepRequests == 1)
    }

    @Test func bedtimeWaitsForRunningTimer() {
        let harness = Harness(now: Self.evening, bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.scheduler.startTimer(minutes: 90)

        harness.advance(seconds: 61 * 60)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.timerEnd != nil)
    }

    @Test func launchingAfterBedtimeDoesNotSleepImmediately() {
        let lateNight = Self.evening.addingTimeInterval(2 * 3600)
        let harness = Harness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))

        harness.advance(seconds: 1)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(harness.scheduler.isPastBedtime)
    }

    @Test func changingBedtimeSchedulesTheNewTime() {
        let harness = Harness(now: Self.evening, bedtime: TimeOfDay(hour: 21, minute: 30))
        harness.advance(seconds: 31 * 60)
        #expect(harness.sleepRequests == 1)

        harness.preferences.bedtime = TimeOfDay(hour: 22, minute: 0)
        #expect(harness.scheduler.nextSleepTime == harness.date(hour: 22))

        harness.advance(seconds: 30 * 60)
        #expect(harness.sleepRequests == 2)
    }

    @Test func disabledBedtimeIsIgnored() {
        let harness = Harness(now: Self.evening, bedtime: TimeOfDay(hour: 21, minute: 1))
        harness.preferences.bedtimeEnabled = false

        harness.advance(seconds: 120)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(!harness.scheduler.isPastBedtime)
    }

    @Test func statusReflectsUrgency() {
        let harness = Harness(now: Self.evening, bedtime: TimeOfDay(hour: 22, minute: 0))
        #expect(harness.scheduler.status == .normal)

        harness.advance(seconds: 31 * 60)
        #expect(harness.scheduler.status == .imminent)

        harness.advance(seconds: 30 * 60)
        #expect(harness.scheduler.status == .pastBedtime)

        harness.scheduler.startTimer(minutes: 120)
        #expect(harness.scheduler.status == .normal)
    }
}
