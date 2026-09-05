import SwiftUI

/// Everything inside the menu bar popover.
///
/// Supplies the environment itself because modifiers on the `MenuBarExtra` scene do not
/// reach its content, and a missing `@Environment` model is a fatal error at runtime.
struct MenuBarContentView: View {
    let preferences: Preferences
    let scheduler: SleepScheduler

    static let width: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimerView()
            Divider()
            BedtimeRow()
            Divider()
            FooterRow()
        }
        .padding(14)
        .frame(width: Self.width)
        .environment(preferences)
        .environment(scheduler)
    }
}

/// One-line bedtime summary with an enable switch. Details live in Settings.
private struct BedtimeRow: View {
    @Environment(Preferences.self) private var preferences
    @Environment(SleepScheduler.self) private var scheduler

    var body: some View {
        @Bindable var preferences = preferences

        HStack {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Bedtime")
                    Text(bedtimeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "bed.double")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Bedtime", isOn: $preferences.bedtimeEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }

    private var bedtimeDescription: String {
        guard preferences.bedtimeEnabled else { return "Off" }
        if let window = scheduler.currentBedtimeWindow {
            let end = Formatting.wallClock(window.end)
            return scheduler.isLightsOut ? "Lights Out until \(end)" : "Until \(end)"
        }
        if let next = scheduler.nextBedtime {
            return "Tonight at \(Formatting.wallClock(next))"
        }
        return "On"
    }
}

private struct FooterRow: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack {
            Button("Settings…") {
                openSettings()
                NSApp.activate()
            }
            .keyboardShortcut(",", modifiers: .command)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .font(.callout)
    }
}

#Preview {
    let preferences = Preferences(defaults: UserDefaults(suiteName: "preview")!)
    MenuBarContentView(preferences: preferences, scheduler: SleepScheduler(preferences: preferences))
}
