import SwiftUI
import os

/// Bedtime, login item, and quit controls shown below the timer in the popover.
struct SettingsView: View {
    @Environment(Preferences.self) private var preferences
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        @Bindable var preferences = preferences

        VStack {
            VStack {
                HStack {
                    Toggle("Bedtime", isOn: $preferences.bedtimeEnabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if preferences.bedtimeEnabled {
                        Picker("", selection: $preferences.bedtimeHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(hour)).tag(hour)
                            }
                        }
                        Picker(":", selection: $preferences.bedtimeMinute) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                    }
                }

                Toggle("Run on Start Up", isOn: $launchAtLogin)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 1))

            Text("[Smartfast Labs](https://smartfast.com)")
        }
        .padding([.bottom, .leading, .trailing], 10)
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
