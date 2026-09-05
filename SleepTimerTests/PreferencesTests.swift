import Foundation
import Testing
@testable import SleepTimer

@MainActor
struct PreferencesTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "PreferencesTests.\(UUID().uuidString)")!
    }

    @Test func defaults() {
        let preferences = Preferences(defaults: makeDefaults())
        #expect(preferences.bedtime == TimeOfDay(hour: 22, minute: 0))
        #expect(preferences.wakeTime == TimeOfDay(hour: 6, minute: 0))
        #expect(!preferences.bedtimeEnabled)
        #expect(!preferences.lightsOutEnabled)
        #expect(preferences.lightsOutMinutes == 15)
        #expect(preferences.idleThresholdSeconds == 120)
        #expect(!preferences.hasCompletedWelcome)
    }

    @Test func persistsChanges() {
        let defaults = makeDefaults()
        let first = Preferences(defaults: defaults)
        first.bedtimeEnabled = true
        first.bedtime = TimeOfDay(hour: 0, minute: 15)
        first.wakeTime = TimeOfDay(hour: 7, minute: 30)
        first.lightsOutEnabled = true
        first.lightsOutMinutes = 20
        first.idleThresholdSeconds = 60
        first.hasCompletedWelcome = true

        let second = Preferences(defaults: defaults)
        #expect(second.bedtimeEnabled)
        #expect(second.bedtime == TimeOfDay(hour: 0, minute: 15))
        #expect(second.wakeTime == TimeOfDay(hour: 7, minute: 30))
        #expect(second.lightsOutEnabled)
        #expect(second.lightsOutMinutes == 20)
        #expect(second.idleThresholdSeconds == 60)
        #expect(second.hasCompletedWelcome)
    }

    @Test func migratesLegacyWelcomeFlag() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: "showWelcome")

        #expect(Preferences(defaults: defaults).hasCompletedWelcome)
    }
}
