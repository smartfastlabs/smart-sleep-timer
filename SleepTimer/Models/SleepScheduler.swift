import AppKit
import Foundation
import Observation
import os

/// A pending sleep the user can still interrupt. Shown as the countdown panel.
struct SleepPrompt: Equatable {
    enum Reason: Equatable {
        case timer
        case bedtime
        case lightsOut
    }

    let reason: Reason
    /// When the Mac sleeps if nobody intervenes.
    let deadline: Date
}

/// Decides when the Mac should sleep, from a manual countdown, the nightly bedtime, or
/// Lights Out mode inside the bedtime window.
///
/// The scheduler ticks once per second while running. All state is main-actor isolated.
/// Dependencies are injectable so the logic can be tested with a fake clock.
@MainActor
@Observable
final class SleepScheduler {
    /// How urgently the UI should present the scheduler's state.
    enum Status: Equatable {
        case normal
        /// Inside the bedtime window with no manual countdown running.
        case pastBedtime
        /// The Mac will sleep within `imminentThreshold`.
        case imminent
    }

    /// Status becomes `.imminent` this close to the next sleep.
    static let imminentThreshold: TimeInterval = 30 * 60
    /// How long the countdown panel gives the user before sleeping.
    static let promptDuration: TimeInterval = 10
    static let quickPickMinutes = [1, 5, 15, 30, 60, 120]

    /// The scheduler's view of the current time, refreshed every tick.
    private(set) var now: Date
    /// When the manual countdown ends, if one is running.
    private(set) var timerEnd: Date?
    /// The quick pick that started the current countdown, for highlighting.
    private(set) var activeQuickPick: Int?
    /// When the Lights Out countdown ends, if one is armed.
    private(set) var lightsOutEnd: Date?
    /// The countdown panel state, if the user is being asked before sleep.
    private(set) var pendingSleep: SleepPrompt?

    /// Start of the bedtime window that has already fired, so bedtime fires once per night.
    @ObservationIgnored private var handledBedtimeStart: Date?
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

        // Launching inside the bedtime window should not put the Mac straight to sleep.
        handledBedtimeStart = currentBedtimeWindow?.start
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

    // MARK: - Bedtime window

    /// The bedtime window containing `now`, if bedtime is enabled and we are inside one.
    /// Windows may cross midnight, so yesterday's window is checked as well as today's.
    var currentBedtimeWindow: DateInterval? {
        guard preferences.bedtimeEnabled else { return nil }
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let window = bedtimeWindow(startingOn: day) else { continue }
            // Half-open: the window ends exactly at wake time.
            if window.start <= now, now < window.end { return window }
        }
        return nil
    }

    /// The next bedtime at or after `now`, if bedtime is enabled.
    var nextBedtime: Date? {
        guard preferences.bedtimeEnabled else { return nil }
        for dayOffset in [0, 1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let start = preferences.bedtime.date(on: day, calendar: calendar) else { continue }
            if start >= now { return start }
        }
        return nil
    }

    private func bedtimeWindow(startingOn day: Date) -> DateInterval? {
        guard let start = preferences.bedtime.date(on: day, calendar: calendar),
              var end = preferences.wakeTime.date(on: start, calendar: calendar) else { return nil }
        if end <= start {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: end) else { return nil }
            end = nextDay
        }
        return DateInterval(start: start, end: end)
    }

    var isPastBedtime: Bool {
        currentBedtimeWindow != nil
    }

    /// Whether Lights Out mode is active right now.
    var isLightsOut: Bool {
        preferences.lightsOutEnabled && isPastBedtime
    }

    // MARK: - Derived state

    /// The next moment the Mac is expected to sleep, if anything is scheduled.
    var nextSleepTime: Date? {
        if let deadline = pendingSleep?.deadline { return deadline }
        if let timerEnd { return timerEnd }
        if let lightsOutEnd { return lightsOutEnd }
        if let window = currentBedtimeWindow {
            return window.start == handledBedtimeStart ? nil : window.start
        }
        return nextBedtime
    }

    func willSleep(within interval: TimeInterval) -> Bool {
        guard let next = nextSleepTime else { return false }
        return next.timeIntervalSince(now) <= interval
    }

    var status: Status {
        if isPastBedtime && timerEnd == nil { return .pastBedtime }
        if willSleep(within: Self.imminentThreshold) { return .imminent }
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

    // MARK: - Timer actions

    /// Starts a countdown from a quick pick. Zero minutes cancels.
    func startTimer(minutes: Int) {
        pendingSleep = nil
        activeQuickPick = minutes > 0 ? minutes : nil
        timerEnd = minutes > 0 ? now.addingTimeInterval(TimeInterval(minutes * 60)) : nil
        Log.scheduler.info("Timer set to \(minutes) minutes")
    }

    func cancelTimer() {
        startTimer(minutes: 0)
    }

    // MARK: - Prompt actions

    /// Sleeps immediately, skipping the rest of the countdown.
    func sleepNow() {
        pendingSleep = nil
        performSleep()
    }

    /// Dismisses the countdown and comes back after the snooze interval.
    func snooze() {
        guard pendingSleep != nil else { return }
        pendingSleep = nil
        activeQuickPick = nil
        timerEnd = now.addingTimeInterval(TimeInterval(preferences.snoozeMinutes * 60))
        Log.scheduler.info("Snoozed for \(self.preferences.snoozeMinutes) minutes")
    }

    /// Dismisses the countdown without sleeping. Inside Lights Out, the countdown re-arms.
    func dismissPrompt() {
        pendingSleep = nil
        Log.scheduler.info("Sleep prompt dismissed")
    }

    // MARK: - System events

    func noteWake() {
        let wakeTime = clock()
        lastWake = wakeTime
        now = wakeTime
        // Anything that came due while asleep has served its purpose.
        pendingSleep = nil
        lightsOutEnd = nil
        if let timerEnd, timerEnd <= now {
            self.timerEnd = nil
            activeQuickPick = nil
        }
        Log.scheduler.info("System woke")
    }

    /// Advances the clock and fires whatever is due. Called every second while running.
    func tick() {
        now = clock()

        if let prompt = pendingSleep {
            if now >= prompt.deadline {
                pendingSleep = nil
                performSleep()
            }
            return
        }

        if let timerEnd, now >= timerEnd {
            self.timerEnd = nil
            activeQuickPick = nil
            Log.scheduler.info("Timer elapsed")
            sleepDue(.timer)
            return
        }

        guard let window = currentBedtimeWindow else {
            lightsOutEnd = nil
            return
        }

        if timerEnd == nil, window.start != handledBedtimeStart {
            handledBedtimeStart = window.start
            lightsOutEnd = nil
            Log.scheduler.info("Bedtime reached")
            sleepDue(.bedtime)
            return
        }

        guard preferences.lightsOutEnabled, timerEnd == nil else {
            lightsOutEnd = nil
            return
        }

        if let lightsOutEnd {
            if now >= lightsOutEnd {
                self.lightsOutEnd = nil
                Log.scheduler.info("Lights Out countdown elapsed")
                sleepDue(.lightsOut)
            }
        } else {
            lightsOutEnd = now.addingTimeInterval(TimeInterval(preferences.lightsOutMinutes * 60))
            Log.scheduler.info("Lights Out armed for \(self.preferences.lightsOutMinutes) minutes")
        }
    }

    /// Sleeps at once if the user is idle; otherwise shows the countdown.
    private func sleepDue(_ reason: SleepPrompt.Reason) {
        let idle = secondsSinceLastActivity
        if idle >= TimeInterval(preferences.idleThresholdSeconds) {
            performSleep()
        } else {
            Log.scheduler.notice("User active \(Int(idle)) seconds ago; showing countdown")
            pendingSleep = SleepPrompt(reason: reason, deadline: now.addingTimeInterval(Self.promptDuration))
        }
    }

    private func performSleep() {
        sleeper.sleep()
    }
}
