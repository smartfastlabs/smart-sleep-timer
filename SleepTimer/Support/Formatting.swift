import Foundation

enum Formatting {
    /// A countdown such as "05:00" or "01:05:00" for the interval between two dates.
    /// Intervals in the past render as "00:00".
    static func countdown(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start).rounded(.down)))
        let duration = Duration.seconds(seconds)
        if seconds >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
        }
        return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }

    /// A short wall-clock time such as "10:30 PM", in the user's locale.
    static func wallClock(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// Label for a quick-pick timer button: "Off", "15m", "2h".
    static func quickPick(minutes: Int) -> String {
        switch minutes {
        case 0: "Off"
        case ..<60: "\(minutes)m"
        default: "\(minutes / 60)h"
        }
    }
}
