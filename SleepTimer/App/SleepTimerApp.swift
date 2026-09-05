import SwiftUI

@main
struct SleepTimerApp: App {
    @State private var preferences: Preferences
    @State private var scheduler: SleepScheduler
    private let promptPresenter: SleepPromptPresenter

    init() {
        let preferences = Preferences()
        let scheduler = SleepScheduler(preferences: preferences)
        promptPresenter = SleepPromptPresenter(scheduler: scheduler, preferences: preferences)
        scheduler.start()
        _preferences = State(initialValue: preferences)
        _scheduler = State(initialValue: scheduler)
    }

    var body: some Scene {
        // Both closures receive the models directly: modifiers on the MenuBarExtra
        // scene itself do not reach its content or label views.
        MenuBarExtra {
            MenuBarContentView(preferences: preferences, scheduler: scheduler)
        } label: {
            MenuBarIcon(scheduler: scheduler)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(preferences)
        }

        Window("Welcome to Smart Sleep Timer", id: "welcome") {
            WelcomeView()
                .environment(preferences)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(preferences.hasCompletedWelcome ? .suppressed : .presented)
    }
}
