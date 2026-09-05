import SwiftUI

/// The countdown shown when a sleep comes due while the user is active.
struct SleepPromptView: View {
    @Environment(SleepScheduler.self) private var scheduler
    @Environment(Preferences.self) private var preferences

    static let width: CGFloat = 420

    var body: some View {
        let remaining = remainingSeconds
        VStack(spacing: 22) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(remaining) / CGFloat(SleepScheduler.promptDuration))
                    .stroke(.tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remaining)
                Text("\(remaining)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: remaining)
            }
            .frame(width: 130, height: 130)

            Text("Your Mac will sleep in ^[\(remaining) second](inflect: true).")
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("Snooze")
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)
                    ForEach(SleepScheduler.snoozeMinutes, id: \.self) { minutes in
                        Button {
                            scheduler.snooze(minutes: minutes)
                        } label: {
                            Text("\(minutes) min").frame(maxWidth: .infinity)
                        }
                        .modifier(DefaultIfTen(minutes: minutes))
                    }
                }

                HStack(spacing: 8) {
                    Button("Cancel") {
                        scheduler.dismissPrompt()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    if preferences.bedtimeEnabled {
                        Button("Off Tonight") {
                            scheduler.disableTonight()
                        }
                        .help("No bedtime or Lights Out until \(wakeTimeDescription)")
                    }

                    Button("Sleep Now") {
                        scheduler.sleepNow()
                    }
                }
            }
            .controlSize(.large)
        }
        .padding(28)
        .frame(width: Self.width)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var remainingSeconds: Int {
        guard let deadline = scheduler.pendingSleep?.deadline else { return 0 }
        return max(0, Int(deadline.timeIntervalSince(scheduler.now).rounded(.up)))
    }

    private var title: String {
        switch scheduler.pendingSleep?.reason {
        case .bedtime: "It's bedtime"
        case .lightsOut: "Lights out"
        case .timer, nil: "Time to sleep"
        }
    }

    private var subtitle: String {
        switch scheduler.pendingSleep?.reason {
        case .bedtime: "Your bedtime is \(Formatting.wallClock(preferences.bedtime.date(on: scheduler.now) ?? scheduler.now))."
        case .lightsOut: "It's past your bedtime."
        case .timer, nil: "Your sleep timer has finished."
        }
    }

    private var wakeTimeDescription: String {
        Formatting.wallClock(preferences.wakeTime.date(on: scheduler.now) ?? scheduler.now)
    }
}

/// Makes the 10-minute snooze the Return-key default, the safest thing a stray keystroke can do.
private struct DefaultIfTen: ViewModifier {
    let minutes: Int

    func body(content: Content) -> some View {
        if minutes == 10 {
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
}
