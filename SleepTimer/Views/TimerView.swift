import SwiftUI

/// The countdown readout and quick-pick buttons shown at the top of the menu bar popover.
struct TimerView: View {
    @Environment(SleepScheduler.self) private var scheduler
    @Environment(Preferences.self) private var preferences

    var body: some View {
        VStack(spacing: 0) {
            headline
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .padding(.vertical, 10)

            HStack {
                ForEach(SleepScheduler.quickPickMinutes, id: \.self) { minutes in
                    quickPickButton(minutes: minutes)
                }
            }
        }
    }

    @ViewBuilder
    private var headline: some View {
        if let end = scheduler.timerEnd {
            Label(Formatting.countdown(from: scheduler.now, to: end), systemImage: "moon.zzz.fill")
        } else if let bedtime = scheduler.nextSleepTime {
            Label(Formatting.wallClock(bedtime), systemImage: "bed.double.circle")
        } else {
            Text(" ")
        }
    }

    private func quickPickButton(minutes: Int) -> some View {
        let isActive = minutes == preferences.sleepIntervalMinutes
        return Button(Formatting.quickPick(minutes: minutes)) {
            scheduler.startTimer(minutes: minutes)
        }
        .background(Color.gray.brightness(isActive ? 0.1 : 0.4))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    let preferences = Preferences(defaults: UserDefaults(suiteName: "preview")!)
    TimerView()
        .environment(preferences)
        .environment(SleepScheduler(preferences: preferences))
}
