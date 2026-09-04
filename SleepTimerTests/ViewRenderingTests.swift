import AppKit
import SwiftUI
import Testing
@testable import SleepTimer

/// Renders top-level views offscreen. A view that reads a model from `@Environment`
/// without one present traps at body evaluation, so these tests catch missing wiring.
@MainActor
struct ViewRenderingTests {
    private func makeModels() -> (Preferences, SleepScheduler) {
        let preferences = Preferences(defaults: UserDefaults(suiteName: "ViewRenderingTests.\(UUID().uuidString)")!)
        return (preferences, SleepScheduler(preferences: preferences))
    }

    private func render(_ view: some View) {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        host.layoutSubtreeIfNeeded()
        #expect(host.fittingSize.width > 0)
    }

    @Test func menuBarContentRenders() {
        let (preferences, scheduler) = makeModels()
        preferences.bedtimeEnabled = true
        scheduler.startTimer(minutes: 15)
        render(MenuBarContentView(preferences: preferences, scheduler: scheduler))
    }

    @Test func menuBarIconRenders() {
        let (_, scheduler) = makeModels()
        render(MenuBarIcon(scheduler: scheduler))
    }

    @Test func welcomeViewRenders() {
        let (preferences, _) = makeModels()
        render(WelcomeView().environment(preferences))
    }
}
