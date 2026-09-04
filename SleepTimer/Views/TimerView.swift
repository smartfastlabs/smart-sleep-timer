import SwiftUI

/// Status readout and quick-pick timer buttons at the top of the popover.
struct TimerView: View {
    @Environment(SleepScheduler.self) private var scheduler
    @Environment(Preferences.self) private var preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            quickPicks
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: headerSymbol)
                .font(.title)
                .foregroundStyle(headerTint)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(headerSubtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if scheduler.timerEnd != nil {
                Button("Cancel") {
                    scheduler.startTimer(minutes: 0)
                }
                .controlSize(.small)
            }
        }
    }

    private var headerSymbol: String {
        if scheduler.timerEnd != nil { return "moon.zzz.fill" }
        switch scheduler.status {
        case .imminent: return "bed.double.fill"
        case .pastBedtime: return "bed.double.fill"
        case .normal: return scheduler.nextSleepTime == nil ? "moon.zzz" : "bed.double"
        }
    }

    private var headerTint: some ShapeStyle {
        switch scheduler.status {
        case .imminent: AnyShapeStyle(.orange)
        case .pastBedtime: AnyShapeStyle(.red)
        case .normal: AnyShapeStyle(.tint)
        }
    }

    private var headerTitle: String {
        if let end = scheduler.timerEnd {
            return Formatting.countdown(from: scheduler.now, to: end)
        }
        if let bedtime = scheduler.nextSleepTime {
            return Formatting.wallClock(bedtime)
        }
        return scheduler.isPastBedtime ? "Past bedtime" : "Timer off"
    }

    private var headerSubtitle: String {
        if let end = scheduler.timerEnd {
            return "Sleeps at \(Formatting.wallClock(end))"
        }
        if scheduler.nextSleepTime != nil {
            return "Bedtime"
        }
        return scheduler.isPastBedtime ? "Start a timer to sleep soon" : "Choose how long to stay awake"
    }

    // MARK: - Quick picks

    private var quickPicks: some View {
        HStack(spacing: 6) {
            ForEach(SleepScheduler.quickPickMinutes.filter { $0 > 0 }, id: \.self) { minutes in
                QuickPickButton(
                    title: Formatting.quickPick(minutes: minutes),
                    isActive: scheduler.timerEnd != nil && minutes == preferences.sleepIntervalMinutes
                ) {
                    scheduler.startTimer(minutes: minutes)
                }
            }
        }
    }
}

private struct QuickPickButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        if isActive {
            Button(action: action) { label }.buttonStyle(.borderedProminent)
        } else {
            Button(action: action) { label }.buttonStyle(.bordered)
        }
    }

    private var label: some View {
        Text(title)
            .font(.callout.weight(.medium))
            .frame(maxWidth: .infinity)
    }
}

#Preview("Idle") {
    let preferences = Preferences(defaults: UserDefaults(suiteName: "preview.idle")!)
    TimerView()
        .padding()
        .environment(preferences)
        .environment(SleepScheduler(preferences: preferences))
}

#Preview("Running") {
    let preferences = Preferences(defaults: UserDefaults(suiteName: "preview.running")!)
    let scheduler = SleepScheduler(preferences: preferences)
    let _ = scheduler.startTimer(minutes: 15)
    TimerView()
        .padding()
        .environment(preferences)
        .environment(scheduler)
}
