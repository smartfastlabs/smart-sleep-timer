import Foundation

/// A clock time without a date, such as 10:30 PM.
struct TimeOfDay: Hashable, Sendable {
    var hour: Int
    var minute: Int

    /// The moment this time of day occurs on the same calendar day as `day`.
    func date(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}
