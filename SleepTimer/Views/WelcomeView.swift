import SwiftUI

/// First-launch window that points the user to the menu bar icon.
struct WelcomeView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    static let supportURL = URL(string: "https://smartfast.com/sleep-timer/support")!

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Smart Sleep Timer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Your ultimate tool for better sleep.")
                .font(.title2)
                .multilineTextAlignment(.center)

            Image("StatusBarIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Smart Sleep Timer runs in the background. Access it anytime from the menu bar.")
                .multilineTextAlignment(.center)

            Text("Once you've found Smart Sleep Timer in the menu bar, click the button below to continue.")
                .multilineTextAlignment(.center)

            HStack {
                Button {
                    preferences.hasCompletedWelcome = true
                    dismiss()
                } label: {
                    Text("I found it").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    openURL(Self.supportURL)
                } label: {
                    Text("I can't find it").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
        .onAppear { NSApp.activate() }
    }
}

#Preview {
    WelcomeView()
        .environment(Preferences(defaults: UserDefaults(suiteName: "preview")!))
}
