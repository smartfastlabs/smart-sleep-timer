import Foundation
import Testing
@testable import SleepTimer

struct FormattingTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test func countdownUnderAnHourShowsMinutesAndSeconds() {
        #expect(Formatting.countdown(from: start, to: start.addingTimeInterval(300)) == "05:00")
        #expect(Formatting.countdown(from: start, to: start.addingTimeInterval(59)) == "00:59")
    }

    @Test func countdownOverAnHourShowsHours() {
        #expect(Formatting.countdown(from: start, to: start.addingTimeInterval(3905)) == "01:05:05")
    }

    @Test func countdownInThePastIsZero() {
        #expect(Formatting.countdown(from: start, to: start.addingTimeInterval(-10)) == "00:00")
    }

    @Test func quickPickLabels() {
        #expect(Formatting.quickPick(minutes: 0) == "Off")
        #expect(Formatting.quickPick(minutes: 15) == "15m")
        #expect(Formatting.quickPick(minutes: 120) == "2h")
    }
}
