//
//  ContentView.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//

import SwiftUI

struct DisableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 220)
            .background(.red)
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct TimerView: View {
    @StateObject var sleepTimer: SleepTimer
    @Environment(\.openWindow) private var openWindow
    
    init (timer: SleepTimer) {
        self._sleepTimer = StateObject(wrappedValue: timer)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            
            let nextSleepTime = sleepTimer.getNextSleepTime()
            if (nextSleepTime == nil) {
                Text("").font(
                    .system(
                        size: 40,
                        weight: .bold,
                        design: .monospaced
                    )
                )
            } else {
                if (sleepTimer.sleepTime != nil) {
                    HStack() {
                        Image(systemName: "moon.zzz.fill").resizable().scaledToFit().frame(width: 24, height: 24)
                        Text("\(describeInterval(from: sleepTimer.currentTime, to: nextSleepTime!))").font(
                            .system(
                                size: 40,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                    }
                    Button("Cancel Timer") {
                        sleepTimer.clear()
                    }.buttonStyle(DisableButtonStyle())
                }
                else {
                    HStack() {
                        Image(systemName: "bed.double.circle").resizable().scaledToFit().frame(width: 24, height: 24)
                        Text("\(getWallTime(time: nextSleepTime!))").font(
                            .system(
                                size: 40,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                    }
                }
            }
            HStack {
                Button("15m") {
                    sleepTimer.setSleepTime(minutes: 1)
                }.clipShape(Capsule())
                
                Button("30m") {
                    sleepTimer.setSleepTime(minutes: 30)
                }.clipShape(Capsule())
                Button("45m") {
                    sleepTimer.setSleepTime(minutes: 45)
                }.clipShape(Capsule())
                Button("1h") {
                    sleepTimer.setSleepTime(minutes: 60)
                }.clipShape(Capsule())
                Button("2h") {
                    sleepTimer.setSleepTime(minutes: 120)
                }.clipShape(Capsule())
            }
        }
    }
}


#Preview {
    TimerView(timer: SleepTimer(config:ConfigService()))
}
