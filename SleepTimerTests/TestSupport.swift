import Foundation
@testable import SleepTimer

/// Drives a `SleepScheduler` with a controllable clock, idle time, and sleep recorder.
@MainActor
final class SchedulerHarness {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    /// A Friday evening at 9:00 PM Pacific.
    static let evening = calendar.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 21))!

    var now: Date
    var idleSeconds: TimeInterval = 600
    private(set) var sleepRequests = 0

    let preferences: Preferences
    private(set) var scheduler: SleepScheduler!

    init(now: Date = SchedulerHarness.evening, bedtime: TimeOfDay? = nil, wakeTime: TimeOfDay? = nil) {
        self.now = now
        let defaults = UserDefaults(suiteName: "SchedulerHarness.\(UUID().uuidString)")!
        preferences = Preferences(defaults: defaults)
        if let bedtime {
            preferences.bedtime = bedtime
            preferences.bedtimeEnabled = true
        }
        if let wakeTime {
            preferences.wakeTime = wakeTime
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

    func advance(minutes: Int) {
        advance(seconds: TimeInterval(minutes * 60))
    }

    /// The given clock time on the same day as `now`.
    func date(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        Self.calendar.date(bySettingHour: hour, minute: minute, second: second, of: now)!
    }

    private struct Sleeper: SystemSleeping {
        unowned let harness: SchedulerHarness
        func sleep() { harness.sleepRequests += 1 }
    }

    private struct Activity: ActivityMonitoring {
        unowned let harness: SchedulerHarness
        func secondsSinceLastInput() -> TimeInterval { harness.idleSeconds }
    }
}
