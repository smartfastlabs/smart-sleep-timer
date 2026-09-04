import SwiftUI

@main
struct SleepTimerApp: App {
    @State private var preferences: Preferences
    @State private var scheduler: SleepScheduler

    init() {
        let preferences = Preferences()
        let scheduler = SleepScheduler(preferences: preferences)
        scheduler.start()
        _preferences = State(initialValue: preferences)
        _scheduler = State(initialValue: scheduler)
    }

    var body: some Scene {
        MenuBarExtra {
            TimerView()
            SettingsView()
        } label: {
            MenuBarIcon(scheduler: scheduler)
        }
        .menuBarExtraStyle(.window)
        .environment(preferences)
        .environment(scheduler)

        Window("Welcome to Smart Sleep Timer", id: "welcome") {
            WelcomeView()
                .environment(preferences)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(preferences.hasCompletedWelcome ? .suppressed : .presented)
    }
}
