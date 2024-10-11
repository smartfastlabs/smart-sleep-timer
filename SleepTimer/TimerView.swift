//
//  ContentView.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//

import SwiftUI
import AppKit


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
    
    func getButton(minutes: Int) -> some View {
        func getName() -> String {
            if (minutes == 0) {
                return "off"
            } else if (minutes < 60) {
                return "\(minutes)m"
            } else {
                let hours = Int(minutes/60)
                return "\(hours)h"
            }
        }
        
        let isActive: Bool = minutes == sleepTimer.config.sleepIntervalMinutes
        return Button(getName()) {
            
            sleepTimer.setSleepInterval(minutes: minutes)
        }.background(Color.gray.brightness(isActive ? 0.1: 0.4)).clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    func closeView() {
        print("ClOSING")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            let nextSleepTime = sleepTimer.getNextSleepTime()
            if (nextSleepTime == nil) {
                Text("").font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .monospaced
                    )
                )
            } else {
                if (sleepTimer.sleepTime != nil) {
                    if (sleepTimer.sleepTime! < Date()) {
                        HStack() {
                            Image(systemName: "exclamationmark.octagon.fill").resizable().scaledToFit().frame(width: 24, height: 24)
                            Text("BED TIME").font(
                                .system(
                                    size: 30,
                                    weight: .bold
                                )
                            )
                            Image(systemName: "exclamationmark.octagon.fill").resizable().scaledToFit().frame(width: 24, height: 24)
                        }.padding(.vertical, 10)
                    } else {
                        HStack() {
                            Image(systemName: "moon.zzz.fill").resizable().scaledToFit().frame(width: 24, height: 24)
                            Text("\(describeInterval(from: sleepTimer.currentTime, to: nextSleepTime!))").font(
                                .system(
                                    size: 30,
                                    weight: .bold,
                                    design: .monospaced
                                )
                            )
                            Image(systemName: "moon.zzz.fill").resizable().scaledToFit().frame(width: 24, height: 24)
                        }.padding(.vertical, 10)
                    }
                } else {
                        HStack() {
                            Image(systemName: "bed.double.circle").resizable().scaledToFit().frame(width: 24, height: 24)
                            Text("\(getWallTime(time: nextSleepTime!))").font(
                                .system(
                                    size: 30,
                                    weight: .bold,
                                    design: .monospaced
                                )
                            )
                            Image(systemName: "bed.double.circle").resizable().scaledToFit().frame(width: 24, height: 24)
                        }.padding(.vertical, 10)
                    }
                }
                HStack {
                    getButton(minutes: 0)
                    getButton(minutes: 5)
                    getButton(minutes: 15)
                    getButton(minutes: 30)
                    getButton(minutes: 60)
                    getButton(minutes: 120)
                }
            }
        }
    }
    
    
    #Preview {
        let configService: ConfigService = ConfigService()
        TimerView(timer: SleepTimer(config:configService))
    }
