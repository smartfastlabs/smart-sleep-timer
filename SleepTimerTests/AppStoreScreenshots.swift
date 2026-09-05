import AppKit
import SwiftUI
import Testing
@testable import SleepTimer

/// Renders Mac App Store screenshots from the real views at Apple's 2880×1800 size
/// (a 1440×900 point canvas at 2x). Run `Scripts/appstore-screenshots.sh` to regenerate
/// `docs/appstore/screenshots/`. Numbered so they upload in order.
@MainActor
struct AppStoreScreenshots {
    private static let outputDirectory = FileManager.default.temporaryDirectory
        .appending(path: "SleepTimerSnapshots/appstore")
    private static let canvas = CGSize(width: 1440, height: 900)

    private static var nineTonight: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now)!
    }

    private func makeHarness() -> SchedulerHarness {
        SchedulerHarness(now: Self.nineTonight, bedtime: TimeOfDay(hour: 22, minute: 0), calendar: .current)
    }

    private func write(_ view: some View, name: String) throws {
        try ScreenshotRenderer.write(
            view, to: Self.outputDirectory.appending(path: "\(name).png"), appearance: .aqua, size: Self.canvas
        )
    }

    private func popover(_ harness: SchedulerHarness) -> some View {
        MenuBarContentView(preferences: harness.preferences, scheduler: harness.scheduler)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
    }

    @Test func s1Hero() throws {
        let harness = makeHarness()
        harness.scheduler.startTimer(minutes: 30)
        harness.advance(seconds: 1)
        try write(
            AppStoreCanvas(
                headline: "Your Mac goes to sleep when you do.",
                detail: "A sleep timer and a bedtime for macOS, living in your menu bar.",
                showIcon: true
            ) {
                popover(harness).scaleEffect(1.7)
            },
            name: "1-hero"
        )
    }

    @Test func s2Timers() throws {
        let harness = makeHarness()
        harness.scheduler.startTimer(minutes: 60)
        harness.advance(seconds: 1)
        try write(
            AppStoreCanvas(
                headline: "Start a timer before the show.",
                detail: "15 minutes to 2 hours, one click away. The popover shows exactly when your Mac will sleep."
            ) {
                popover(harness).scaleEffect(1.7)
            },
            name: "2-timers"
        )
    }

    @Test func s3Countdown() throws {
        let harness = makeHarness()
        harness.idleSeconds = 5
        harness.advance(minutes: 61)
        harness.advance(seconds: 3)
        let desktop = ReadmeDesktop(blurred: true) {
            SleepPromptCard()
                .environment(harness.preferences)
                .environment(harness.scheduler)
        }
        .frame(width: 1280, height: 800)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 40, y: 20)
        .scaleEffect(0.6)
        // scaleEffect does not change layout size; claim only the scaled footprint.
        .frame(width: 1280 * 0.6, height: 800 * 0.6)

        try write(
            AppStoreCanvas(
                headline: "Still typing? It asks first.",
                detail: "A ten-second countdown with room to snooze. Walked away already? Your Mac just sleeps."
            ) {
                desktop
            },
            name: "3-countdown"
        )
    }

    @Test func s4LightsOut() throws {
        let harness = makeHarness()
        harness.preferences.lightsOutEnabled = true
        harness.now = harness.now.addingTimeInterval(2 * 3600)
        harness.scheduler.noteWake()
        harness.advance(seconds: 1)
        try write(
            AppStoreCanvas(
                headline: "Bedtime. Then Lights Out.",
                detail: "After bedtime, your Mac goes back to sleep every time you wake it, until morning."
            ) {
                popover(harness).scaleEffect(1.7)
            },
            name: "4-lights-out"
        )
    }

    @Test func s5Settings() throws {
        let harness = makeHarness()
        harness.preferences.lightsOutEnabled = true
        let settings = SettingsView()
            .environment(harness.preferences)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
            .scaleEffect(1.05)
        try write(
            AppStoreCanvas(
                headline: "Everything in one window.",
                detail: "Bedtime, wake time, Lights Out, how long to wait before sleeping without asking, and open at login."
            ) {
                settings
            },
            name: "5-settings"
        )
    }
}

/// A 1440×900 marketing canvas: headline on the left, the feature on the right.
private struct AppStoreCanvas<Content: View>: View {
    let headline: String
    let detail: String
    var showIcon = false
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.14, blue: 0.46), Color(red: 0.05, green: 0.06, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 22) {
                    if showIcon {
                        Image(nsImage: Bundle.main.image(forResource: "AppIcon") ?? NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
                            .padding(.bottom, 8)
                    }
                    Text(headline)
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 520, alignment: .leading)
                .padding(.leading, 90)

                Spacer(minLength: 0)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 1440, height: 900)
        .clipped()
    }
}
