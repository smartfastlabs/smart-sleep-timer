import AppKit
import SwiftUI
import Testing
@testable import SleepTimer

/// Renders each top-level view to PNG files for visual review.
///
/// Files land in `SleepTimerSnapshots` inside the temporary directory, or in
/// `SNAPSHOT_DIR` when that environment variable is set.
@MainActor
struct SnapshotTests {
    private static var outputDirectory: URL? {
        if let override = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"] {
            return URL(filePath: override)
        }
        return FileManager.default.temporaryDirectory.appending(path: "SleepTimerSnapshots")
    }

    private func snapshot(_ view: some View, name: String) throws {
        guard let directory = Self.outputDirectory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            // Real windows paint their own background; give the offscreen host one too.
            let host = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
            host.appearance = NSAppearance(named: appearance)
            let size = host.fittingSize
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: .borderless, backing: .buffered, defer: false
            )
            window.contentView = host
            host.layoutSubtreeIfNeeded()
            host.displayIfNeeded()

            let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let data = try #require(bitmap.representation(using: .png, properties: [:]))
            try data.write(to: directory.appending(path: "\(name)-\(suffix).png"))
        }
    }

    private func popover(_ harness: SchedulerHarness) -> some View {
        MenuBarContentView(preferences: harness.preferences, scheduler: harness.scheduler)
    }

    @Test func popoverIdle() throws {
        try snapshot(popover(SchedulerHarness()), name: "popover-idle")
    }

    @Test func popoverRunning() throws {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.scheduler.startTimer(minutes: 15)
        try snapshot(popover(harness), name: "popover-running")
    }

    @Test func popoverBedtimeScheduled() throws {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 23, minute: 59))
        try snapshot(popover(harness), name: "popover-bedtime")
    }

    @Test func popoverLightsOut() throws {
        let harness = SchedulerHarness(now: SchedulerHarness.evening.addingTimeInterval(2 * 3600), bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        harness.advance(seconds: 1)
        try snapshot(popover(harness), name: "popover-lightsout")
    }

    @Test func sleepPrompt() throws {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.idleSeconds = 5
        harness.advance(minutes: 61)
        harness.advance(seconds: 3)
        try snapshot(
            SleepPromptCard().environment(harness.preferences).environment(harness.scheduler),
            name: "prompt"
        )
    }

    @Test func settings() throws {
        let harness = SchedulerHarness(bedtime: TimeOfDay(hour: 22, minute: 0))
        harness.preferences.lightsOutEnabled = true
        try snapshot(SettingsView().environment(harness.preferences), name: "settings")
    }

    @Test func welcome() throws {
        let harness = SchedulerHarness()
        try snapshot(WelcomeView().environment(harness.preferences), name: "welcome")
    }
}
