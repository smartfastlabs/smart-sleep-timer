import AppKit
import SwiftUI
import Testing
@testable import SleepTimer

/// Renders the images used by README.md from the real views, so the screenshots never
/// drift from the app. Run `Scripts/screenshots.sh` to regenerate `docs/screenshots/`.
///
/// Uses the local calendar with a fixed 9:00 PM "now", so times read naturally.
@MainActor
struct ReadmeScreenshots {
    private static let outputDirectory = FileManager.default.temporaryDirectory
        .appending(path: "SleepTimerSnapshots/readme")

    private static var nineTonight: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now)!
    }

    private func makeHarness() -> SchedulerHarness {
        SchedulerHarness(now: Self.nineTonight, bedtime: TimeOfDay(hour: 22, minute: 0), calendar: .current)
    }

    /// Renders `view` at its fitting size, or at `size` when given, in one appearance.
    private func write(_ view: some View, name: String, appearance: NSAppearance.Name, size: CGSize? = nil, scale: CGFloat = 2) throws {
        try FileManager.default.createDirectory(at: Self.outputDirectory, withIntermediateDirectories: true)
        let host = NSHostingView(rootView: AnyView(view))
        host.appearance = NSAppearance(named: appearance)
        let frameSize = size ?? host.fittingSize
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: frameSize), styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: frameSize)
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()

        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        bitmap.size = host.bounds.size
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: Self.outputDirectory.appending(path: "\(name).png"))
    }

    private func writeBoth(_ view: some View, name: String, size: CGSize? = nil) throws {
        try write(view.background(Color(nsColor: .windowBackgroundColor)), name: "\(name)-light", appearance: .aqua, size: size)
        try write(view.background(Color(nsColor: .windowBackgroundColor)), name: "\(name)-dark", appearance: .darkAqua, size: size)
    }

    // MARK: - Images

    @Test func hero() throws {
        try write(ReadmeHero(), name: "hero", appearance: .darkAqua, size: CGSize(width: 1200, height: 400))
    }

    @Test func menuBarStates() throws {
        try write(ReadmeMenuBarStates(), name: "menubar", appearance: .aqua)
    }

    @Test func popoverRunning() throws {
        let harness = makeHarness()
        harness.scheduler.startTimer(minutes: 30)
        harness.advance(seconds: 1)
        try writeBoth(MenuBarContentView(preferences: harness.preferences, scheduler: harness.scheduler), name: "popover")
    }

    @Test func popoverLightsOut() throws {
        let harness = makeHarness()
        harness.preferences.lightsOutEnabled = true
        harness.now = harness.now.addingTimeInterval(2 * 3600)  // 11 PM
        harness.scheduler.noteWake()
        harness.advance(seconds: 1)
        try writeBoth(MenuBarContentView(preferences: harness.preferences, scheduler: harness.scheduler), name: "popover-lightsout")
    }

    @Test func overlayOnDesktop() throws {
        let harness = makeHarness()
        harness.idleSeconds = 5
        harness.advance(minutes: 61)
        harness.advance(seconds: 3)
        // The real overlay uses a system material, which cannot sample a backdrop when
        // rendered offscreen, so the mock desktop is blurred directly here instead.
        let overlay = ReadmeDesktop(blurred: true) {
            SleepPromptCard()
                .environment(harness.preferences)
                .environment(harness.scheduler)
        }
        try write(overlay, name: "overlay", appearance: .darkAqua, size: CGSize(width: 1280, height: 800))
    }

    @Test func settings() throws {
        let harness = makeHarness()
        harness.preferences.lightsOutEnabled = true
        try writeBoth(SettingsView().environment(harness.preferences), name: "settings")
    }
}

// MARK: - README-only views

/// Banner: app icon, name, and tagline on a night gradient.
private struct ReadmeHero: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.13, blue: 0.42), Color(red: 0.04, green: 0.05, blue: 0.16)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            HStack(spacing: 44) {
                Image(nsImage: Bundle.main.image(forResource: "AppIcon") ?? NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.4), radius: 30, y: 16)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Smart Sleep Timer")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Your Mac goes to sleep when you do.")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                    HStack(spacing: 10) {
                        pill("Menu bar", "moon.zzz")
                        pill("Bedtime", "bed.double")
                        pill("Lights Out", "lightbulb.slash")
                    }
                    .padding(.top, 6)
                }
            }
        }
    }

    private func pill(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.14), in: Capsule())
    }
}

/// The three menu bar icon states in light and dark menu bars.
private struct ReadmeMenuBarStates: View {
    private let states: [(SleepScheduler.Status, String)] = [
        (.normal, "Idle or scheduled"),
        (.imminent, "Sleeping within 30 min"),
        (.pastBedtime, "Past bedtime / Lights Out"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            row(background: Color(white: 0.93), tint: .black)
            row(background: Color(white: 0.16), tint: .white)
            HStack(spacing: 0) {
                ForEach(states, id: \.1) { _, label in
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 200)
                }
            }
            .padding(.vertical, 10)
            .background(Color.white)
            .foregroundStyle(.black)
        }
        .frame(width: 600)
    }

    private func row(background: Color, tint: Color) -> some View {
        HStack(spacing: 0) {
            ForEach(states, id: \.1) { status, _ in
                Image(MenuBarIcon.assetName(for: status))
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                    .foregroundStyle(tint)
                    .frame(width: 200)
            }
        }
        .frame(height: 44)
        .background(background)
    }
}

/// A mock desktop with a few windows so the overlay's blur shows.
private struct ReadmeDesktop<Content: View>: View {
    var blurred = false
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.35, blue: 0.75), Color(red: 0.55, green: 0.20, blue: 0.60), Color(red: 0.95, green: 0.45, blue: 0.30)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                mockWindow(title: "Notes", width: 560, height: 420, lines: 9)
                    .offset(x: -240, y: 30)
                mockWindow(title: "Safari", width: 640, height: 480, lines: 12)
                    .offset(x: 200, y: -40)
            }
            .blur(radius: blurred ? 28 : 0)
            .overlay(Color.black.opacity(blurred ? 0.3 : 0))
            content
        }
        .clipped()
    }

    private func mockWindow(title: String, width: CGFloat, height: CGFloat, lines: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in Circle().fill(.gray.opacity(0.5)).frame(width: 12, height: 12) }
                Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor))
            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<lines, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.25))
                        .frame(width: CGFloat(180 + (i * 137) % 300), height: 12)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
    }
}
