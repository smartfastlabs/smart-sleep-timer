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

    private func makeModels() -> (Preferences, SleepScheduler) {
        let preferences = Preferences(defaults: UserDefaults(suiteName: "SnapshotTests.\(UUID().uuidString)")!)
        return (preferences, SleepScheduler(preferences: preferences))
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

    @Test func popoverIdle() throws {
        let (preferences, scheduler) = makeModels()
        try snapshot(MenuBarContentView(preferences: preferences, scheduler: scheduler), name: "popover-idle")
    }

    @Test func popoverRunning() throws {
        let (preferences, scheduler) = makeModels()
        preferences.bedtimeEnabled = true
        scheduler.startTimer(minutes: 15)
        try snapshot(MenuBarContentView(preferences: preferences, scheduler: scheduler), name: "popover-running")
    }

    @Test func popoverBedtimeScheduled() throws {
        let (preferences, scheduler) = makeModels()
        preferences.bedtimeEnabled = true
        preferences.bedtime = TimeOfDay(hour: 23, minute: 59)
        try snapshot(MenuBarContentView(preferences: preferences, scheduler: scheduler), name: "popover-bedtime")
    }

    @Test func settings() throws {
        let (preferences, _) = makeModels()
        preferences.bedtimeEnabled = true
        try snapshot(SettingsView().environment(preferences), name: "settings")
    }

    @Test func welcome() throws {
        let (preferences, _) = makeModels()
        try snapshot(WelcomeView().environment(preferences), name: "welcome")
    }
}
