import Foundation
import Testing
@testable import SleepTimer

@MainActor
struct PreferencesTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "PreferencesTests.\(UUID().uuidString)")!
    }

    @Test func defaultsToTenPMBedtime() {
        let preferences = Preferences(defaults: makeDefaults())
        #expect(preferences.bedtime == TimeOfDay(hour: 22, minute: 0))
        #expect(!preferences.bedtimeEnabled)
        #expect(!preferences.hasCompletedWelcome)
    }

    @Test func persistsChanges() {
        let defaults = makeDefaults()
        let first = Preferences(defaults: defaults)
        first.bedtimeEnabled = true
        first.bedtime = TimeOfDay(hour: 0, minute: 15)
        first.sleepIntervalMinutes = 30
        first.hasCompletedWelcome = true

        let second = Preferences(defaults: defaults)
        #expect(second.bedtimeEnabled)
        #expect(second.bedtime == TimeOfDay(hour: 0, minute: 15))
        #expect(second.sleepIntervalMinutes == 30)
        #expect(second.hasCompletedWelcome)
    }

    @Test func migratesLegacyWelcomeFlag() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: "showWelcome")

        #expect(Preferences(defaults: defaults).hasCompletedWelcome)
    }
}
