import SwiftUI
import os

/// The Settings window (Command-comma).
struct SettingsView: View {
    @Environment(Preferences.self) private var preferences
    @State private var launchAtLogin = LoginItem.isEnabled

    static let websiteURL = URL(string: "https://smartfast.com")!

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            Section {
                Toggle("Sleep at bedtime", isOn: $preferences.bedtimeEnabled)
                DatePicker("Bedtime", selection: binding(for: \.bedtime), displayedComponents: .hourAndMinute)
                DatePicker("Wake time", selection: binding(for: \.wakeTime), displayedComponents: .hourAndMinute)
            } header: {
                Text("Bedtime")
            } footer: {
                Text("At bedtime your Mac goes to sleep, or shows a countdown if you're using it. Bedtime lasts until wake time.")
            }
            .disabled(!preferences.bedtimeEnabled)

            Section {
                Toggle("Lights Out mode", isOn: $preferences.lightsOutEnabled)
                Picker("Sleep again after", selection: $preferences.lightsOutMinutes) {
                    ForEach(Preferences.lightsOutMinuteOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .disabled(!preferences.lightsOutEnabled)
            } footer: {
                Text("Between bedtime and wake time, your Mac goes back to sleep this long after you wake it.")
            }
            .disabled(!preferences.bedtimeEnabled)

            Section {
                Picker("Ask if I've used my Mac within", selection: $preferences.idleThresholdSeconds) {
                    ForEach(Preferences.idleThresholdOptions, id: \.self) { seconds in
                        Text(Self.describe(seconds: seconds)).tag(seconds)
                    }
                }
            } header: {
                Text("Going to sleep")
            } footer: {
                Text("When a timer ends, your Mac sleeps right away if you've been idle longer than this. Otherwise you get a \(Int(SleepScheduler.promptDuration))-second countdown with options to snooze.")
            }

            Section("General") {
                Toggle("Open at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
            }

            Section("About") {
                LabeledContent("Version", value: Self.versionString)
                Link("Smartfast Labs", destination: Self.websiteURL)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func binding(for keyPath: ReferenceWritableKeyPath<Preferences, TimeOfDay>) -> Binding<Date> {
        Binding(
            get: { preferences[keyPath: keyPath].date(on: .now) ?? .now },
            set: { preferences[keyPath: keyPath] = TimeOfDay(from: $0) }
        )
    }

    private static func describe(seconds: Int) -> String {
        seconds < 60 ? "\(seconds) seconds" : (seconds == 60 ? "1 minute" : "\(seconds / 60) minutes")
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard enabled != LoginItem.isEnabled else { return }
        do {
            try LoginItem.setEnabled(enabled)
        } catch {
            Log.system.error("Could not update login item: \(error.localizedDescription, privacy: .public)")
            launchAtLogin = LoginItem.isEnabled
        }
    }
}

#Preview {
    SettingsView()
        .environment(Preferences(defaults: UserDefaults(suiteName: "preview")!))
}
