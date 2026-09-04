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
                DatePicker("Bedtime", selection: bedtimeBinding, displayedComponents: .hourAndMinute)
                    .disabled(!preferences.bedtimeEnabled)
            } header: {
                Text("Bedtime")
            } footer: {
                Text("Your Mac goes to sleep at bedtime unless you are actively using it.")
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
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var bedtimeBinding: Binding<Date> {
        Binding(
            get: { preferences.bedtime.date(on: .now) ?? .now },
            set: { preferences.bedtime = TimeOfDay(from: $0) }
        )
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
