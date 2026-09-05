import Foundation
import Observation

/// User settings, persisted to `UserDefaults` as they change.
///
/// Key names from earlier releases are kept so existing users keep their settings.
@MainActor
@Observable
final class Preferences {
    private enum Key {
        static let bedtimeEnabled = "bedTimeEnabled"
        static let bedtimeHour = "bedTimeHour"
        static let bedtimeMinute = "bedTimeMinute"
        static let wakeHour = "wakeTimeHour"
        static let wakeMinute = "wakeTimeMinute"
        static let lightsOutEnabled = "lightsOutEnabled"
        static let lightsOutMinutes = "lightsOutMinutes"
        static let idleThresholdSeconds = "idleThresholdSeconds"
        static let snoozeMinutes = "snoozeMinutes"
        static let hasCompletedWelcome = "hasCompletedWelcome"
        /// Pre-1.1 key with inverted meaning; read once for migration.
        static let legacyShowWelcome = "showWelcome"
    }

    static let defaultBedtime = TimeOfDay(hour: 22, minute: 0)
    static let defaultWakeTime = TimeOfDay(hour: 6, minute: 0)
    static let defaultLightsOutMinutes = 15
    static let defaultIdleThresholdSeconds = 120
    static let defaultSnoozeMinutes = 10

    static let lightsOutMinuteOptions = [5, 10, 15, 20, 30, 45, 60]
    static let idleThresholdOptions = [30, 60, 120, 300, 600]
    static let snoozeMinuteOptions = [5, 10, 15, 30]

    private let defaults: UserDefaults

    /// Whether the Mac sleeps when bedtime arrives.
    var bedtimeEnabled: Bool {
        didSet { defaults.set(bedtimeEnabled, forKey: Key.bedtimeEnabled) }
    }

    var bedtimeHour: Int {
        didSet { defaults.set(bedtimeHour, forKey: Key.bedtimeHour) }
    }

    var bedtimeMinute: Int {
        didSet { defaults.set(bedtimeMinute, forKey: Key.bedtimeMinute) }
    }

    var wakeHour: Int {
        didSet { defaults.set(wakeHour, forKey: Key.wakeHour) }
    }

    var wakeMinute: Int {
        didSet { defaults.set(wakeMinute, forKey: Key.wakeMinute) }
    }

    /// Whether, between bedtime and wake time, the Mac keeps going back to sleep
    /// `lightsOutMinutes` after each wake.
    var lightsOutEnabled: Bool {
        didSet { defaults.set(lightsOutEnabled, forKey: Key.lightsOutEnabled) }
    }

    var lightsOutMinutes: Int {
        didSet { defaults.set(lightsOutMinutes, forKey: Key.lightsOutMinutes) }
    }

    /// Input within this many seconds of a timer ending shows the countdown instead of sleeping.
    var idleThresholdSeconds: Int {
        didSet { defaults.set(idleThresholdSeconds, forKey: Key.idleThresholdSeconds) }
    }

    var snoozeMinutes: Int {
        didSet { defaults.set(snoozeMinutes, forKey: Key.snoozeMinutes) }
    }

    var hasCompletedWelcome: Bool {
        didSet { defaults.set(hasCompletedWelcome, forKey: Key.hasCompletedWelcome) }
    }

    var bedtime: TimeOfDay {
        get { TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute) }
        set {
            bedtimeHour = newValue.hour
            bedtimeMinute = newValue.minute
        }
    }

    /// End of the bedtime window. Earlier than `bedtime` means the window crosses midnight.
    var wakeTime: TimeOfDay {
        get { TimeOfDay(hour: wakeHour, minute: wakeMinute) }
        set {
            wakeHour = newValue.hour
            wakeMinute = newValue.minute
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.bedtimeHour: Self.defaultBedtime.hour,
            Key.bedtimeMinute: Self.defaultBedtime.minute,
            Key.wakeHour: Self.defaultWakeTime.hour,
            Key.wakeMinute: Self.defaultWakeTime.minute,
            Key.lightsOutMinutes: Self.defaultLightsOutMinutes,
            Key.idleThresholdSeconds: Self.defaultIdleThresholdSeconds,
            Key.snoozeMinutes: Self.defaultSnoozeMinutes,
        ])

        bedtimeEnabled = defaults.bool(forKey: Key.bedtimeEnabled)
        bedtimeHour = defaults.integer(forKey: Key.bedtimeHour)
        bedtimeMinute = defaults.integer(forKey: Key.bedtimeMinute)
        wakeHour = defaults.integer(forKey: Key.wakeHour)
        wakeMinute = defaults.integer(forKey: Key.wakeMinute)
        lightsOutEnabled = defaults.bool(forKey: Key.lightsOutEnabled)
        lightsOutMinutes = defaults.integer(forKey: Key.lightsOutMinutes)
        idleThresholdSeconds = defaults.integer(forKey: Key.idleThresholdSeconds)
        snoozeMinutes = defaults.integer(forKey: Key.snoozeMinutes)

        if let completed = defaults.object(forKey: Key.hasCompletedWelcome) as? Bool {
            hasCompletedWelcome = completed
        } else {
            // Earlier versions stored `showWelcome = false` once the welcome screen had been shown.
            hasCompletedWelcome = (defaults.object(forKey: Key.legacyShowWelcome) as? Bool) == false
        }
    }
}
