import Foundation
import Observation

/// User settings, persisted to `UserDefaults` as they change.
///
/// Key names are kept from earlier releases so existing users keep their settings.
@MainActor
@Observable
final class Preferences {
    private enum Key {
        static let bedtimeEnabled = "bedTimeEnabled"
        static let bedtimeHour = "bedTimeHour"
        static let bedtimeMinute = "bedTimeMinute"
        static let sleepIntervalMinutes = "sleepIntervalMinutes"
        static let hasCompletedWelcome = "hasCompletedWelcome"
        /// Pre-1.1 key with inverted meaning; read once for migration.
        static let legacyShowWelcome = "showWelcome"
    }

    static let defaultBedtime = TimeOfDay(hour: 22, minute: 0)

    private let defaults: UserDefaults

    var bedtimeEnabled: Bool {
        didSet { defaults.set(bedtimeEnabled, forKey: Key.bedtimeEnabled) }
    }

    var bedtimeHour: Int {
        didSet { defaults.set(bedtimeHour, forKey: Key.bedtimeHour) }
    }

    var bedtimeMinute: Int {
        didSet { defaults.set(bedtimeMinute, forKey: Key.bedtimeMinute) }
    }

    /// The most recent quick-pick choice, in minutes. Zero means "off".
    var sleepIntervalMinutes: Int {
        didSet { defaults.set(sleepIntervalMinutes, forKey: Key.sleepIntervalMinutes) }
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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.bedtimeHour: Self.defaultBedtime.hour,
            Key.bedtimeMinute: Self.defaultBedtime.minute,
        ])

        bedtimeEnabled = defaults.bool(forKey: Key.bedtimeEnabled)
        bedtimeHour = defaults.integer(forKey: Key.bedtimeHour)
        bedtimeMinute = defaults.integer(forKey: Key.bedtimeMinute)
        sleepIntervalMinutes = defaults.integer(forKey: Key.sleepIntervalMinutes)

        if let completed = defaults.object(forKey: Key.hasCompletedWelcome) as? Bool {
            hasCompletedWelcome = completed
        } else {
            // Earlier versions stored `showWelcome = false` once the welcome screen had been shown.
            hasCompletedWelcome = (defaults.object(forKey: Key.legacyShowWelcome) as? Bool) == false
        }
    }
}
