import AppKit
import Testing
@testable import SleepTimer

/// Shows and hides the real countdown window through the presenter, yielding to the main
/// actor so observation tasks and AppKit layout passes run. Catches window sizing loops
/// that only appear on screen.
@MainActor
struct SleepPromptPresenterTests {
    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    @Test func showsWindowWhilePromptIsPendingAndHidesAfter() async throws {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.idleSeconds = 1
        let presenter = SleepPromptPresenter(scheduler: harness.scheduler, preferences: harness.preferences)

        harness.advance(minutes: 61)
        #expect(harness.scheduler.pendingSleep != nil)
        try await settle()
        #expect(presenter.isShowingWindow, "first show, frame \(String(describing: presenter.windowFrame))")

        // Let the countdown tick a few times with the window on screen.
        for _ in 0..<3 {
            harness.advance(seconds: 1)
            try await settle()
        }
        #expect(presenter.isShowingWindow, "after ticking, frame \(String(describing: presenter.windowFrame))")

        harness.scheduler.dismissPrompt()
        try await settle()
        #expect(!presenter.isShowingWindow, "after dismiss")

        // Showing again reuses the window without issue.
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)
        try await settle()
        #expect(presenter.isShowingWindow, "second show, frame \(String(describing: presenter.windowFrame))")

        harness.scheduler.dismissPrompt()
        try await settle()
        #expect(!presenter.isShowingWindow, "after second dismiss")
    }
}
