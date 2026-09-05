import AppKit
import Foundation
import Observation
import os

/// A pending sleep the user can still interrupt. Shown as the countdown overlay.
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

/// A running countdown toward sleep, started from a quick pick or a snooze.
struct Countdown: Equatable {
    let end: Date
    /// Why the Mac will sleep when this ends. Snoozes keep the reason they interrupted.
    let reason: SleepPrompt.Reason
    /// The quick pick that started it, for highlighting. Nil for snoozes.
    let quickPick: Int?
}

/// Decides when the Mac should sleep, from a manual countdown, the nightly bedtime, or
/// Lights Out mode inside the bedtime window.
///
/// The scheduler ticks once per second while running. All state is main-actor isolated.
/// Dependencies are injectable so the logic can be tested with a fake clock.
///
/// Rules, in priority order on each tick:
/// 1. A pending prompt sleeps the Mac at its deadline; nothing else fires meanwhile.
/// 2. A countdown that has ended comes due.
/// 3. Entering the bedtime window comes due once per window. Launching, waking, or
///    sleeping inside the window all count the window as handled.
/// 4. Inside the window with Lights Out on and no countdown, a Lights Out countdown is
///    armed, and comes due when it ends.
/// "Coming due" sleeps immediately if the user has been idle past the threshold,
/// otherwise it shows the prompt.
@MainActor
@Observable
final class SleepScheduler {
    /// How urgently the UI should present the scheduler's state.
    enum Status: Equatable {
        case normal
        /// Inside the bedtime window with no countdown running.
        case pastBedtime
        /// The Mac will sleep within `imminentThreshold`.
        case imminent
    }

    /// Status becomes `.imminent` this close to the next sleep.
    static let imminentThreshold: TimeInterval = 30 * 60
    /// How long the countdown overlay gives the user before sleeping.
    static let promptDuration: TimeInterval = 10
    static let quickPickMinutes = [15, 30, 60, 120]
    static let snoozeMinutes = [15, 30, 60]

    /// The scheduler's view of the current time, refreshed every tick. Views that show a
    /// live countdown read this; everything else should prefer the stored properties.
    private(set) var now: Date
    private(set) var countdown: Countdown?
    /// When the Lights Out countdown ends, if one is armed.
    private(set) var lightsOutEnd: Date?
    /// The overlay state, if the user is being asked before sleep.
    private(set) var pendingSleep: SleepPrompt?
    /// While set and in the future, bedtime and Lights Out are suspended ("Off tonight").
    private(set) var disabledUntil: Date?
    /// Urgency for the menu bar icon. Stored, and only assigned when it changes, so the
    /// icon does not re-render on every tick.
    private(set) var status: Status = .normal

    /// Start of the bedtime window that has already been handled, so bedtime fires once.
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
        refreshStatus()
    }

    // MARK: - Lifecycle

    /// Starts the once-per-second tick and begins observing system wake. Safe to call once.
    func start() {
        guard ticker == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // Common modes keep the tick alive during scrolling and dragging; tolerance lets
        // the system coalesce it with other timers to save energy.
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer

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

    private var schedule: BedtimeSchedule {
        BedtimeSchedule(bedtime: preferences.bedtime, wakeTime: preferences.wakeTime, calendar: calendar)
    }

    /// Whether the user chose "Not tonight" and wake time has not yet passed.
    var isOffTonight: Bool {
        guard let disabledUntil else { return false }
        return now < disabledUntil
    }

    /// The bedtime window containing `now`, unless bedtime is disabled or off for tonight.
    var currentBedtimeWindow: DateInterval? {
        guard preferences.bedtimeEnabled, !isOffTonight else { return nil }
        return schedule.window(containing: now)
    }

    /// The next bedtime window starting at or after `now`, skipping one that is off for tonight.
    var nextBedtimeWindow: DateInterval? {
        guard preferences.bedtimeEnabled else { return nil }
        let from = disabledUntil.map { max($0, now) } ?? now
        return schedule.nextWindow(startingAtOrAfter: from)
    }

    var nextBedtime: Date? {
        nextBedtimeWindow?.start
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
        if let end = countdown?.end { return end }
        if let lightsOutEnd { return lightsOutEnd }
        if let window = currentBedtimeWindow {
            return window.start == handledBedtimeStart ? nil : window.start
        }
        return nextBedtime
    }

    /// Seconds since the user last did anything, treating system wake as activity.
    var secondsSinceLastActivity: TimeInterval {
        var idle = activity.secondsSinceLastInput()
        if let lastWake {
            idle = min(idle, now.timeIntervalSince(lastWake))
        }
        return idle
    }

    private func refreshStatus() {
        let next: Status
        if isPastBedtime && countdown == nil {
            next = .pastBedtime
        } else if let nextSleepTime, nextSleepTime.timeIntervalSince(now) <= Self.imminentThreshold {
            next = .imminent
        } else {
            next = .normal
        }
        if next != status {
            status = next
        }
    }

    // MARK: - Countdown actions

    /// Starts a countdown from a quick pick, replacing any running one.
    func startTimer(minutes: Int) {
        precondition(minutes > 0, "Use cancelTimer() to stop the countdown")
        pendingSleep = nil
        countdown = Countdown(end: now.addingTimeInterval(TimeInterval(minutes * 60)), reason: .timer, quickPick: minutes)
        refreshStatus()
        Log.scheduler.info("Timer set to \(minutes) minutes")
    }

    func cancelTimer() {
        countdown = nil
        refreshStatus()
        Log.scheduler.info("Timer cancelled")
    }

    // MARK: - Prompt actions

    /// Dismisses the overlay and comes back after `minutes`, for the same reason.
    func snooze(minutes: Int) {
        guard let prompt = pendingSleep else { return }
        pendingSleep = nil
        countdown = Countdown(end: now.addingTimeInterval(TimeInterval(minutes * 60)), reason: prompt.reason, quickPick: nil)
        refreshStatus()
        Log.scheduler.info("Snoozed for \(minutes) minutes")
    }

    /// Dismisses the overlay and suspends bedtime and Lights Out until the current window
    /// ends, or until tonight's window ends if bedtime has not started yet.
    func disableTonight() {
        pendingSleep = nil
        lightsOutEnd = nil
        defer { refreshStatus() }
        guard let window = currentBedtimeWindow ?? nextBedtimeWindow else { return }
        disabledUntil = window.end
        Log.scheduler.info("Bedtime off until \(window.end, privacy: .public)")
    }

    /// Undoes "Not tonight".
    func resumeTonight() {
        disabledUntil = nil
        // Do not fire bedtime retroactively for a window we are already inside.
        handledBedtimeStart = currentBedtimeWindow?.start ?? handledBedtimeStart
        refreshStatus()
        Log.scheduler.info("Bedtime resumed")
    }

    // MARK: - System events

    func noteWake() {
        now = clock()
        lastWake = now
        // Anything that came due while asleep has served its purpose, and waking inside
        // the window is not a bedtime event; Lights Out handles re-sleeping.
        pendingSleep = nil
        lightsOutEnd = nil
        if let end = countdown?.end, end <= now {
            countdown = nil
        }
        if let window = currentBedtimeWindow {
            handledBedtimeStart = window.start
        }
        refreshStatus()
        Log.scheduler.info("System woke")
    }

    /// Advances the clock and fires whatever is due. Called every second while running.
    func tick() {
        now = clock()
        defer { refreshStatus() }

        if let disabledUntil, now >= disabledUntil || !preferences.bedtimeEnabled {
            self.disabledUntil = nil
        }

        if let prompt = pendingSleep {
            if now >= prompt.deadline {
                pendingSleep = nil
                performSleep()
            }
            return
        }

        if let countdown, now >= countdown.end {
            self.countdown = nil
            Log.scheduler.info("Countdown ended")
            sleepDue(countdown.reason)
            return
        }

        guard let window = currentBedtimeWindow else {
            lightsOutEnd = nil
            return
        }

        if countdown == nil, window.start != handledBedtimeStart {
            handledBedtimeStart = window.start
            lightsOutEnd = nil
            Log.scheduler.info("Bedtime reached")
            sleepDue(.bedtime)
            return
        }

        guard preferences.lightsOutEnabled, countdown == nil else {
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

    /// Sleeps at once if the user is idle; otherwise shows the overlay.
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
        // Sleeping inside the window, for any reason, is tonight's bedtime.
        if let window = currentBedtimeWindow {
            handledBedtimeStart = window.start
        }
        sleeper.sleep()
    }
}
