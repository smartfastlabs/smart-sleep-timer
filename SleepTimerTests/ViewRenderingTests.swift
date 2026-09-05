import AppKit
import SwiftUI
import Testing
@testable import SleepTimer

/// Renders top-level views offscreen. A view that reads a model from `@Environment`
/// without one present traps at body evaluation, so these tests catch missing wiring.
@MainActor
struct ViewRenderingTests {
    private func render(_ view: some View) {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        host.layoutSubtreeIfNeeded()
        #expect(host.fittingSize.width > 0)
    }

    @Test func menuBarContentRenders() {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.scheduler.startTimer(minutes: 15)
        render(MenuBarContentView(preferences: harness.preferences, scheduler: harness.scheduler))
    }

    @Test func menuBarIconRenders() {
        render(MenuBarIcon(scheduler: SchedulerHarness().scheduler))
    }

    @Test func sleepPromptRenders() {
        let harness = SchedulerHarness()
        harness.idleSeconds = 1
        harness.scheduler.startTimer(minutes: 1)
        harness.advance(seconds: 61)
        render(SleepPromptCard().environment(harness.preferences).environment(harness.scheduler))
    }

    @Test func settingsViewRenders() {
        render(SettingsView().environment(SchedulerHarness().preferences))
    }

    @Test func welcomeViewRenders() {
        render(WelcomeView().environment(SchedulerHarness().preferences))
    }
}
