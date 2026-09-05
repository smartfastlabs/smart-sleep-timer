import SwiftUI

/// Full-screen overlay shown when a sleep comes due while the user is active:
/// blurs everything behind it and centers the card.
struct SleepPromptView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            SleepPromptCard()
        }
    }
}

/// The message and choices in the middle of the overlay.
struct SleepPromptCard: View {
    @Environment(SleepScheduler.self) private var scheduler

    var body: some View {
        let remaining = remainingSeconds
        VStack(spacing: 28) {
            Image(systemName: symbol)
                .font(.system(size: 88, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.pulse, options: .repeating)
                .frame(height: 100)

            VStack(spacing: 8) {
                Text(headline)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Your Mac will sleep in ^[\(remaining) second](inflect: true).")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: remaining)
            }

            HStack(spacing: 12) {
                ForEach(SleepScheduler.snoozeMinutes, id: \.self) { minutes in
                    choice(Self.snoozeLabel(minutes: minutes)) {
                        scheduler.snooze(minutes: minutes)
                    }
                    .modifier(DefaultIfFirst(isFirst: minutes == SleepScheduler.snoozeMinutes.first))
                }
                choice("Not tonight") {
                    scheduler.disableTonight()
                }
            }
            .controlSize(.extraLarge)
        }
        .padding(44)
        .frame(width: 640)
        .fixedSize(horizontal: false, vertical: true)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 40, y: 20)
    }

    private func choice(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
        }
    }

    static func snoozeLabel(minutes: Int) -> String {
        minutes < 60 ? "\(minutes) more minutes" : (minutes == 60 ? "1 more hour" : "\(minutes / 60) more hours")
    }

    private var remainingSeconds: Int {
        guard let deadline = scheduler.pendingSleep?.deadline else { return 0 }
        return max(0, Int(deadline.timeIntervalSince(scheduler.now).rounded(.up)))
    }

    private var symbol: String {
        switch scheduler.pendingSleep?.reason {
        case .lightsOut: "lightbulb.slash.fill"
        case .bedtime, .timer, nil: "moon.stars.fill"
        }
    }

    private var headline: String {
        switch scheduler.pendingSleep?.reason {
        case .bedtime: "Time for bed"
        case .lightsOut: "Lights out"
        case .timer, nil: "Time to call it a night"
        }
    }
}

/// Makes the first snooze the Return-key default, the gentlest thing a stray keystroke can do.
private struct DefaultIfFirst: ViewModifier {
    let isFirst: Bool

    func body(content: Content) -> some View {
        if isFirst {
            content.keyboardShortcut(.defaultAction)
        } else {
            content
        }
    }
}

#Preview {
    let preferences = Preferences(defaults: UserDefaults(suiteName: "preview")!)
    SleepPromptView()
        .environment(preferences)
        .environment(SleepScheduler(preferences: preferences))
        .frame(width: 1200, height: 800)
}
