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

            if scheduler.countdown != nil {
                Button("Cancel") {
                    scheduler.cancelTimer()
                }
                .controlSize(.small)
            }
        }
    }

    private var headerSymbol: String {
        if scheduler.countdown != nil { return "moon.zzz.fill" }
        if scheduler.lightsOutEnd != nil { return "lightbulb.slash.fill" }
        if scheduler.isPastBedtime { return "bed.double.fill" }
        return scheduler.nextSleepTime == nil ? "moon.zzz" : "bed.double"
    }

    private var headerTint: some ShapeStyle {
        switch scheduler.status {
        case .imminent: AnyShapeStyle(.orange)
        case .pastBedtime: AnyShapeStyle(.red)
        case .normal: AnyShapeStyle(.tint)
        }
    }

    private var headerTitle: String {
        if let end = scheduler.countdown?.end ?? scheduler.lightsOutEnd {
            return Formatting.countdown(from: scheduler.now, to: end)
        }
        if scheduler.isPastBedtime {
            return scheduler.isLightsOut ? "Lights Out" : "Past bedtime"
        }
        if let bedtime = scheduler.nextSleepTime {
            return Formatting.wallClock(bedtime)
        }
        return "Timer off"
    }

    private var headerSubtitle: String {
        if let end = scheduler.countdown?.end {
            return "Sleeps at \(Formatting.wallClock(end))"
        }
        if let end = scheduler.lightsOutEnd {
            return "Lights Out · sleeps at \(Formatting.wallClock(end))"
        }
        if let window = scheduler.currentBedtimeWindow {
            return scheduler.isLightsOut
                ? "Until \(Formatting.wallClock(window.end))"
                : "Start a timer to sleep soon"
        }
        if scheduler.nextSleepTime != nil {
            return "Bedtime"
        }
        return "Choose how long to stay awake"
    }

    // MARK: - Quick picks

    private var quickPicks: some View {
        HStack(spacing: 6) {
            ForEach(SleepScheduler.quickPickMinutes, id: \.self) { minutes in
                QuickPickButton(
                    title: Formatting.quickPick(minutes: minutes),
                    isActive: minutes == scheduler.countdown?.quickPick
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
