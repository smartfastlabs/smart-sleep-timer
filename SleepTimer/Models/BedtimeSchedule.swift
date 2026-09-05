import Foundation

/// The nightly window between bedtime and wake time. Pure date math, no state.
///
/// A window may cross midnight: bedtime 10:00 PM and wake time 6:00 AM is one
/// eight-hour window. Windows are half-open; wake time itself is outside.
struct BedtimeSchedule {
    var bedtime: TimeOfDay
    var wakeTime: TimeOfDay
    var calendar: Calendar

    /// The window whose bedtime falls on the same calendar day as `day`.
    func window(startingOn day: Date) -> DateInterval? {
        guard let start = bedtime.date(on: day, calendar: calendar),
              var end = wakeTime.date(on: start, calendar: calendar) else { return nil }
        if end <= start {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: end) else { return nil }
            end = nextDay
        }
        return DateInterval(start: start, end: end)
    }

    /// The window containing `date`, if any. Checks the window that started yesterday as
    /// well as today's, since one may still be open past midnight.
    func window(containing date: Date) -> DateInterval? {
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let window = window(startingOn: day) else { continue }
            if window.start <= date, date < window.end { return window }
        }
        return nil
    }

    /// The first window whose bedtime is at or after `date`.
    func nextWindow(startingAtOrAfter date: Date) -> DateInterval? {
        for dayOffset in [0, 1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let window = window(startingOn: day), window.start >= date else { continue }
            return window
        }
        return nil
    }
}
