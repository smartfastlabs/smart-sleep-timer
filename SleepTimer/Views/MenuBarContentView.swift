import SwiftUI

/// Everything inside the menu bar popover.
///
/// Supplies the environment itself because modifiers on the `MenuBarExtra` scene do not
/// reach its content, and a missing `@Environment` model is a fatal error at runtime.
struct MenuBarContentView: View {
    let preferences: Preferences
    let scheduler: SleepScheduler

    var body: some View {
        VStack(spacing: 0) {
            TimerView()
            SettingsView()
        }
        .environment(preferences)
        .environment(scheduler)
    }
}

#Preview {
    let preferences = Preferences(defaults: UserDefaults(suiteName: "preview")!)
    MenuBarContentView(preferences: preferences, scheduler: SleepScheduler(preferences: preferences))
}
