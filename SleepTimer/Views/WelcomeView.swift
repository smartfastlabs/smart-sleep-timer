import SwiftUI

/// First-launch window: explains what the app does and where to find it.
struct WelcomeView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    static let supportURL = URL(string: "https://smartfast.com/sleep-timer/support")!

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                // Read from the bundle rather than NSApp.applicationIconImage, which can serve a
                // stale cached icon after the artwork changes.
                Image(nsImage: Bundle.main.image(forResource: "AppIcon") ?? NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                Text("Smart Sleep Timer")
                    .font(.largeTitle.weight(.bold))
                Text("Puts your Mac to sleep when you mean to stop.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                feature("timer", "Quick timers", "Pick 5 minutes to 2 hours from the menu bar.")
                feature("bed.double", "Bedtime", "Sleeps at the same time every night.")
                feature("hand.raised", "Stays out of your way", "Waits if you're still using your Mac.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 6) {
                Text("Look for")
                Image(MenuBarIcon.assetName(for: .normal))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 16)
                Text("in your menu bar to get started.")
            }
            .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Button {
                    preferences.hasCompletedWelcome = true
                    dismiss()
                } label: {
                    Text("Got it").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                Button("I don't see it in my menu bar") {
                    openURL(Self.supportURL)
                }
                .buttonStyle(.link)
                .font(.callout)
            }
        }
        .padding(32)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { NSApp.activate() }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(detail).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(Preferences(defaults: UserDefaults(suiteName: "preview")!))
}
