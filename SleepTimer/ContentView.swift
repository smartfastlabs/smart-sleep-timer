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
            .padding(2)
            .frame(maxWidth: .infinity)
            .background(.red)
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct ContentView: View {
    @StateObject var sleepTimer: SleepTimer

    
    init (timer: SleepTimer) {
        self._sleepTimer = StateObject(wrappedValue: timer)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            if (sleepTimer.nextSleepTime != nil) {
               
                Text("\(sleepTimer.humanReadable!)").font(.system(size: 48, weight: .bold, design: .monospaced))
                if (sleepTimer.sleepTime != nil) {
                    Button("Cancel Timer") {
                        sleepTimer.clear()
                    }.buttonStyle(DisableButtonStyle())
                }
            }
            HStack {
                Button("15m") {
                    sleepTimer.setSleepTime(minutes: 15)
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

            Toggle(
                "Enable Bedtime",
                isOn: $sleepTimer.bedTimeEnabled
            ).onChange(of: sleepTimer.bedTimeEnabled) {
                sleepTimer.saveBedTime()
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            if (sleepTimer.bedTimeEnabled) {
                HStack {
                    Picker("", selection: $sleepTimer.bedTimeHour) {
                        ForEach(1...12, id: \.self) { hour in
                            Text(String(hour)).tag(String(hour))
                        }
                    }.onChange(of: sleepTimer.bedTimeHour) {
                        sleepTimer.saveBedTime()
                    }
                    Picker(":", selection: $sleepTimer.bedTimeMinute) {
                        ForEach(0...59, id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }.onChange(of: sleepTimer.bedTimeMinute) {
                        sleepTimer.saveBedTime()
                    }
                    Picker("", selection: $sleepTimer.bedTimeAmPm) {
                        Text("AM").tag("AM")
                        Text("PM").tag("PM")
                    }.onChange(of: sleepTimer.bedTimeAmPm) {
                        sleepTimer.saveBedTime()
                    }
                }
            }

        }
        .padding()
    }

}


#Preview {
    ContentView(timer: SleepTimer())
}
