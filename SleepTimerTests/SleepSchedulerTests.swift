import Foundation
import Testing
@testable import SleepTimer

@MainActor
struct SleepSchedulerTests {
    private let evening = SchedulerHarness.evening

    // MARK: Manual timer

    @Test func timerCountsDownAndSleepsWhenIdle() {
        let harness = SchedulerHarness()
        harness.scheduler.startTimer(minutes: 5)

        #expect(harness.scheduler.nextSleepTime == evening.addingTimeInterval(300))
        #expect(harness.scheduler.countdown?.quickPick == 5)

        harness.advance(seconds: 299)
        #expect(harness.sleepRequests == 0)

        harness.advance(seconds: 2)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.countdown?.end == nil)
        #expect(harness.scheduler.countdown?.quickPick == nil)
    }

    @Test func cancelClearsCountdown() {
        let harness = SchedulerHarness()
        harness.scheduler.startTimer(minutes: 30)
        harness.scheduler.cancelTimer()

        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(harness.scheduler.countdown?.quickPick == nil)
    }

    // MARK: Countdown prompt

    @Test func activeUserGetsCountdownInsteadOfSleep() {
        let harness = SchedulerHarness()
        harness.idleSeconds = 10
        harness.scheduler.startTimer(minutes: 1)

        harness.advance(seconds: 61)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.pendingSleep == SleepPrompt(reason: .timer, deadline: harness.now.addingTimeInterval(10)))
        #expect(harness.scheduler.countdown?.end == nil)

        harness.advance(seconds: 9)
        #expect(harness.sleepRequests == 0)

        harness.advance(seconds: 1)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.pendingSleep == nil)
    }

    @Test func idleThresholdIsConfigurable() {
        let harness = SchedulerHarness()
        harness.preferences.idleThresholdSeconds = 30
        harness.idleSeconds = 45
        harness.scheduler.startTimer(minutes: 1)

        harness.advance(seconds: 61)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.pendingSleep == nil)
    }

    @Test func systemWakeCountsAsActivity() {
        let harness = SchedulerHarness()
        harness.scheduler.startTimer(minutes: 1)
        harness.now = harness.now.addingTimeInterval(55)
        harness.scheduler.noteWake()

        harness.advance(seconds: 6)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.pendingSleep?.reason == .timer)
    }

    @Test(arguments: [15, 30, 60])
    func snoozeDismissesPromptAndStartsTimer(minutes: Int) {
        let harness = SchedulerHarness()
        harness.idleSeconds = 10
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)

        harness.scheduler.snooze(minutes: minutes)
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(harness.scheduler.countdown?.end == harness.now.addingTimeInterval(TimeInterval(minutes * 60)))
        #expect(harness.scheduler.countdown?.quickPick == nil)
    }

    // MARK: Off tonight

    @Test func offTonightSuspendsLightsOutUntilWakeTime() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0), wakeTime: TimeOfDay(hour: 6, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.preferences.lightsOutMinutes = 5
        harness.idleSeconds = 3
        harness.advance(seconds: 1)
        harness.advance(minutes: 5)
        #expect(harness.scheduler.pendingSleep?.reason == .lightsOut)

        harness.scheduler.disableTonight()
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(harness.scheduler.isOffTonight)
        #expect(!harness.scheduler.isPastBedtime)
        #expect(harness.scheduler.status == .normal)

        harness.advance(minutes: 6 * 60)  // 5:05 AM
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.lightsOutEnd == nil)

        harness.advance(minutes: 60)  // 6:05 AM, window over
        #expect(!harness.scheduler.isOffTonight)
        #expect(harness.scheduler.nextSleepTime == harness.date(hour: 22))

        harness.advance(minutes: 16 * 60)  // 10:05 PM next night
        #expect(harness.scheduler.isPastBedtime)
        #expect(harness.scheduler.pendingSleep?.reason == .bedtime)
    }

    @Test func offTonightBeforeBedtimeSkipsTonightsWindow() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.idleSeconds = 3
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)
        #expect(harness.scheduler.pendingSleep?.reason == .timer)

        harness.scheduler.disableTonight()
        let tomorrow = SchedulerHarness.calendar.date(byAdding: .day, value: 1, to: harness.date(hour: 22))
        #expect(harness.scheduler.nextSleepTime == tomorrow)

        harness.advance(minutes: 60)  // 10:01 PM
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(!harness.scheduler.isPastBedtime)
    }

    @Test func resumeTonightRestoresLightsOutWithoutRefiringBedtime() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.advance(seconds: 1)
        harness.scheduler.disableTonight()

        harness.scheduler.resumeTonight()
        harness.advance(seconds: 1)
        #expect(harness.scheduler.isPastBedtime)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.lightsOutEnd != nil)
    }

    @Test func offTonightWithoutBedtimeDoesNothing() {
        let harness = SchedulerHarness()
        harness.idleSeconds = 3
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)

        harness.scheduler.disableTonight()
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(!harness.scheduler.isOffTonight)
    }

    @Test func startingTimerDismissesPrompt() {
        let harness = SchedulerHarness()
        harness.idleSeconds = 10
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)

        harness.scheduler.startTimer(minutes: 15)
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(harness.scheduler.countdown?.end == harness.now.addingTimeInterval(900))
    }

    @Test func wakeClearsPromptAndExpiredTimer() {
        let harness = SchedulerHarness()
        harness.idleSeconds = 10
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)
        #expect(harness.scheduler.pendingSleep != nil)

        harness.now = harness.now.addingTimeInterval(3600)
        harness.scheduler.noteWake()
        harness.scheduler.tick()
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(harness.scheduler.countdown?.end == nil)
        #expect(harness.sleepRequests == 0)
    }

    // MARK: Bedtime window

    @Test func bedtimeWindowCrossesMidnight() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0), wakeTime: TimeOfDay(hour: 6, minute: 0))
        #expect(!harness.scheduler.isPastBedtime)

        harness.advance(minutes: 60)  // 10:00 PM
        #expect(harness.scheduler.isPastBedtime)

        harness.advance(minutes: 4 * 60)  // 2:00 AM
        #expect(harness.scheduler.isPastBedtime)

        harness.advance(minutes: 3 * 60 + 59)  // 5:59 AM
        #expect(harness.scheduler.isPastBedtime)

        harness.advance(minutes: 1)  // 6:00 AM
        #expect(!harness.scheduler.isPastBedtime)
        #expect(harness.scheduler.nextSleepTime == harness.date(hour: 22))
    }

    @Test func bedtimeWindowWithinOneDay() {
        let noon = SchedulerHarness.calendar.date(bySettingHour: 12, minute: 0, second: 0, of: evening)!
        let harness = SchedulerHarness(now: noon, bedtime: TimeOfDay(hour: 13, minute: 0), wakeTime: TimeOfDay(hour: 15, minute: 0))

        harness.advance(minutes: 60)
        #expect(harness.scheduler.isPastBedtime)
        harness.advance(minutes: 120)
        #expect(!harness.scheduler.isPastBedtime)
    }

    @Test func bedtimeFiresOnceWhenWindowOpens() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        #expect(harness.scheduler.nextSleepTime == harness.date(hour: 22))

        harness.advance(seconds: 59 * 60)
        #expect(harness.sleepRequests == 0)

        harness.advance(seconds: 61)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.nextSleepTime == nil)

        harness.advance(minutes: 10)
        #expect(harness.sleepRequests == 1)
    }

    @Test func activeUserAtBedtimeGetsCountdown() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.idleSeconds = 5

        harness.advance(minutes: 61)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.pendingSleep?.reason == .bedtime)
    }

    @Test func bedtimeWaitsForRunningTimer() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.scheduler.startTimer(minutes: 90)

        harness.advance(minutes: 61)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.countdown?.end != nil)
    }

    @Test func launchingInsideWindowDoesNotSleepImmediately() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))

        harness.advance(seconds: 1)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(harness.scheduler.isPastBedtime)
    }

    @Test func changingBedtimeSchedulesTheNewTime() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 21, minute: 30))
        harness.advance(minutes: 31)
        #expect(harness.sleepRequests == 1)

        harness.preferences.bedtime = TimeOfDay(hour: 22, minute: 0)
        #expect(harness.scheduler.nextSleepTime == harness.date(hour: 22))

        harness.advance(minutes: 30)
        #expect(harness.sleepRequests == 2)
    }

    @Test func disabledBedtimeIsIgnored() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 21, minute: 1))
        harness.preferences.bedtimeEnabled = false

        harness.advance(minutes: 2)
        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(!harness.scheduler.isPastBedtime)
    }

    // MARK: Lights Out

    @Test func lightsOutArmsAndReArmsInsideWindow() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.preferences.lightsOutMinutes = 15

        harness.advance(seconds: 1)
        #expect(harness.scheduler.isLightsOut)
        #expect(harness.scheduler.lightsOutEnd == harness.now.addingTimeInterval(15 * 60))
        #expect(harness.scheduler.status == .pastBedtime)

        harness.advance(minutes: 15)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.lightsOutEnd == nil)

        harness.advance(seconds: 1)
        #expect(harness.scheduler.lightsOutEnd == harness.now.addingTimeInterval(15 * 60))
    }

    @Test func lightsOutPromptsActiveUserAndSnoozes() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.preferences.lightsOutMinutes = 5
        harness.idleSeconds = 3

        harness.advance(seconds: 1)
        harness.advance(minutes: 5)
        #expect(harness.scheduler.pendingSleep?.reason == .lightsOut)

        harness.scheduler.snooze(minutes: 10)
        #expect(harness.scheduler.countdown?.end == harness.now.addingTimeInterval(600))
        harness.advance(minutes: 10)
        #expect(harness.scheduler.pendingSleep?.reason == .lightsOut)
    }

    @Test func lightsOutStopsWhenWindowEnds() {
        let lateNight = evening.addingTimeInterval(8 * 3600 + 50 * 60)  // 5:50 AM next day
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0), wakeTime: TimeOfDay(hour: 6, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.preferences.lightsOutMinutes = 15

        harness.advance(seconds: 1)
        #expect(harness.scheduler.lightsOutEnd != nil)

        harness.advance(minutes: 10)
        #expect(!harness.scheduler.isPastBedtime)
        #expect(harness.scheduler.lightsOutEnd == nil)
        #expect(harness.sleepRequests == 0)
    }

    @Test func lightsOutDefersToManualTimer() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.scheduler.startTimer(minutes: 30)

        harness.advance(minutes: 20)
        #expect(harness.scheduler.lightsOutEnd == nil)
        #expect(harness.scheduler.status == .imminent)
    }

    @Test func wakeReArmsLightsOut() {
        let lateNight = evening.addingTimeInterval(2 * 3600)
        let harness = SchedulerHarness(now: lateNight, bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.preferences.lightsOutMinutes = 15
        harness.advance(seconds: 1)
        harness.advance(minutes: 15)
        #expect(harness.sleepRequests == 1)

        harness.now = harness.now.addingTimeInterval(3600)
        harness.scheduler.noteWake()
        harness.scheduler.tick()
        #expect(harness.scheduler.lightsOutEnd == harness.now.addingTimeInterval(15 * 60))
    }

    @Test func snoozeKeepsTheOriginalReason() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.idleSeconds = 3
        harness.advance(minutes: 61)
        #expect(harness.scheduler.pendingSleep?.reason == .bedtime)

        harness.scheduler.snooze(minutes: 15)
        #expect(harness.scheduler.countdown?.reason == .bedtime)
        #expect(harness.scheduler.countdown?.quickPick == nil)

        harness.advance(minutes: 15)
        #expect(harness.scheduler.pendingSleep?.reason == .bedtime)
    }

    // MARK: Waking inside the window

    @Test func wakingInsideWindowDoesNotFireBedtime() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        // Lid closed at 9 PM, opened at 11 PM.
        harness.now = harness.now.addingTimeInterval(2 * 3600)
        harness.scheduler.noteWake()
        harness.advance(seconds: 1)

        #expect(harness.sleepRequests == 0)
        #expect(harness.scheduler.pendingSleep == nil)
        #expect(harness.scheduler.nextSleepTime == nil)
        #expect(harness.scheduler.status == .pastBedtime)
    }

    @Test func wakingInsideWindowArmsLightsOut() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.preferences.lightsOutMinutes = 15
        harness.now = harness.now.addingTimeInterval(2 * 3600)
        harness.scheduler.noteWake()
        harness.advance(seconds: 1)

        #expect(harness.scheduler.pendingSleep == nil)
        #expect(harness.scheduler.lightsOutEnd == harness.now.addingTimeInterval(15 * 60))
    }

    @Test func sleepingInsideWindowCountsAsBedtime() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.scheduler.startTimer(minutes: 90)  // 9:00 PM timer ends 10:30 PM, inside the window
        harness.advance(minutes: 91)
        #expect(harness.sleepRequests == 1)

        harness.now = harness.now.addingTimeInterval(30 * 60)
        harness.scheduler.noteWake()
        harness.advance(seconds: 1)
        #expect(harness.sleepRequests == 1)
        #expect(harness.scheduler.pendingSleep == nil)
    }

    // MARK: Status

    @Test func statusReflectsUrgency() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        #expect(harness.scheduler.status == .normal)

        harness.advance(minutes: 31)
        #expect(harness.scheduler.status == .imminent)

        harness.advance(minutes: 30)
        #expect(harness.scheduler.status == .pastBedtime)

        harness.scheduler.startTimer(minutes: 120)
        #expect(harness.scheduler.status == .normal)
    }
}
