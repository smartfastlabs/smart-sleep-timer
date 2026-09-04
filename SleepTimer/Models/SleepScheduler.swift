import AppKit
import Foundation
import Observation
import os

/// Decides when the Mac should sleep, from either a manual countdown or the daily bedtime.
///
/// The scheduler ticks once per second while running. All state is main-actor isolated.
/// Dependencies are injectable so the logic can be tested with a fake clock.
@MainActor
@Observable
final class SleepScheduler {
    /// How urgently the UI should present the scheduler's state.
    enum Status: Equatable {
        case normal
        /// Bedtime has passed today and no countdown is running.
        case pastBedtime
        /// The Mac will sleep within `imminentThreshold`.
        case imminent
    }

    /// Sleep is skipped if the user provided input within this window.
    static let activityGracePeriod: TimeInterval = 2 * 60
    /// Status becomes `.imminent` this close to the next sleep.
    static let imminentThreshold: TimeInterval = 30 * 60
    static let quickPickMinutes = [0, 5, 15, 30, 60, 120]

    /// The scheduler's view of the current time, refreshed every tick.
    private(set) var now: Date
    /// When the manual countdown ends, if one is running.
    private(set) var timerEnd: Date?

    /// The specific bedtime instant that has already fired, so it fires once.
    @ObservationIgnored private var handledBedtime: Date?
    @ObservationIgnored private var lastWake: Date?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var wakeObserver: (any NSObjectProtocol)?

    private let preferences: Preferences
    private let calendar: Calendar
    private let clock: () -> Date
    private let sleeper: any SystemSleeping
    private let activity: any ActivityMonitoring

    init(
        preferences: Preferences,
        calendar: Calendar = .current,
        clock: @escaping () -> Date = { Date() },
        sleeper: any SystemSleeping = PMSetSleeper(),
        activity: any ActivityMonitoring = SystemActivityMonitor()
    ) {
        self.preferences = preferences
        self.calendar = calendar
        self.clock = clock
        self.sleeper = sleeper
        self.activity = activity
        self.now = clock()

        // Launching after bedtime should not put the Mac straight to sleep.
        if let bedtime = todaysBedtime, now >= bedtime {
            handledBedtime = bedtime
        }
    }

    // MARK: - Lifecycle

    /// Starts the once-per-second tick and begins observing system wake. Safe to call once.
    func start() {
        guard ticker == nil else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.noteWake() }
        }
        Log.scheduler.info("Scheduler started")
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        wakeObserver = nil
    }

    // MARK: - Derived state

    /// Today's bedtime, or nil when bedtime is disabled.
    var todaysBedtime: Date? {
        guard preferences.bedtimeEnabled else { return nil }
        return preferences.bedtime.date(on: now, calendar: calendar)
    }

    var isPastBedtime: Bool {
        guard let bedtime = todaysBedtime else { return false }
        return now >= bedtime
    }

    /// The next moment the Mac is expected to sleep, if anything is scheduled.
    var nextSleepTime: Date? {
        if let timerEnd { return timerEnd }
        if let bedtime = todaysBedtime, bedtime != handledBedtime { return bedtime }
        return nil
    }

    func willSleep(within interval: TimeInterval) -> Bool {
        guard let next = nextSleepTime else { return false }
        return next.timeIntervalSince(now) <= interval
    }

    var status: Status {
        if willSleep(within: Self.imminentThreshold) { return .imminent }
        if isPastBedtime && timerEnd == nil { return .pastBedtime }
        return .normal
    }

    /// Seconds since the user last did anything, treating system wake as activity.
    var secondsSinceLastActivity: TimeInterval {
        var idle = activity.secondsSinceLastInput()
        if let lastWake {
            idle = min(idle, now.timeIntervalSince(lastWake))
        }
        return idle
    }

    // MARK: - Actions

    /// Starts a countdown and remembers the choice. Zero minutes cancels.
    func startTimer(minutes: Int) {
        preferences.sleepIntervalMinutes = minutes
        timerEnd = minutes > 0 ? now.addingTimeInterval(TimeInterval(minutes * 60)) : nil
        Log.scheduler.info("Timer set to \(minutes) minutes")
    }

    /// Restarts the countdown from now without changing the remembered quick pick.
    func extendTimer(minutes: Int) {
        timerEnd = now.addingTimeInterval(TimeInterval(minutes * 60))
        Log.scheduler.info("Timer extended by \(minutes) minutes")
    }

    func noteWake() {
        lastWake = clock()
        Log.scheduler.info("System woke")
    }

    /// Advances the clock and fires whatever is due. Called every second while running.
    func tick() {
        now = clock()

        if let bedtime = todaysBedtime, timerEnd == nil, bedtime != handledBedtime, now >= bedtime {
            handledBedtime = bedtime
            Log.scheduler.info("Bedtime reached")
            sleepIfIdle()
        } else if let timerEnd, now >= timerEnd {
            self.timerEnd = nil
            Log.scheduler.info("Timer elapsed")
            sleepIfIdle()
        }
    }

    private func sleepIfIdle() {
        let idle = secondsSinceLastActivity
        guard idle >= Self.activityGracePeriod else {
            Log.scheduler.notice("Skipping sleep: user was active \(Int(idle)) seconds ago")
            return
        }
        sleeper.sleep()
    }
}
