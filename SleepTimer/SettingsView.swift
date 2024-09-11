//
//  ContentView.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//

import SwiftUI
import UserNotifications

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

struct SettingsView: View {
    @StateObject var sleepTimer: SleepTimer
    @StateObject var config: ConfigService
    
    @State var isExpanded = false
    @State var subviewHeight : CGFloat = 0
    
    init (timer: SleepTimer, config: ConfigService) {
        self._config = StateObject(wrappedValue: config)
        self._sleepTimer = StateObject(wrappedValue: timer)
    }
    
    func setRunOnStartUp() {
        config.set(runOnStartUp: config.runOnStartUp)
        
        if (config.runOnStartUp) {
            
        }
        
    }
    
    func setWarnBeforeSleeping() {
        config.set(warnBeforeSleeping: config.warnBeforeSleeping)
        
        if (config.warnBeforeSleeping) {
            let current = UNUserNotificationCenter.current()
            
            current.getNotificationSettings(completionHandler: { (settings) in
                if settings.authorizationStatus == .notDetermined {
                    print("DUNNO")
                    current.requestAuthorization(options: [.sound , .alert , .badge ], completionHandler: { (granted, error) in
                        if (error != nil) {
                            print("AUTH ERROR", error)
                            return
                        }
                        print("AUTH GRANTED", granted)
                        // Enable or disable features based on the authorization.
                    })
                } else if settings.authorizationStatus == .denied {
                    print("NOPE")
                    
                } else if settings.authorizationStatus == .authorized {
                    print("yup")
                }
            })

        }
    }
    var body: some View {
        VStack() {
            Text(isExpanded ? "- Settings -" : "+ Settings +" ).onTapGesture(perform: {
                self.isExpanded = !self.isExpanded
            }).padding(5)
            if (isExpanded) {
                VStack {
                    VStack {
                        HStack {
                            Toggle(
                                "Bedtime",
                                isOn: $config.bedTimeEnabled
                            ).onChange(of: config.bedTimeEnabled) {
                                config.set(bedTimeEnabled: config.bedTimeEnabled)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            
                            if (config.bedTimeEnabled) {
                                
                                Picker("", selection: $config.bedTimeHour) {
                                    ForEach(0...23, id: \.self) { hour in
                                        Text(String(hour)).tag(String(hour))
                                    }
                                }.onChange(of: config.bedTimeHour) {
                                    config.set(bedTimeHour: config.bedTimeHour)
                                }
                                Picker(":", selection: $config.bedTimeMinute) {
                                    ForEach(0...59, id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }.onChange(of: config.bedTimeMinute) {
                                    config.set(bedTimeMinute: config.bedTimeMinute)
                                }
                            }
                        }
                        Toggle(
                            "Notify Before Sleeping",
                            isOn: $config.warnBeforeSleeping
                        ).onChange(of: config.warnBeforeSleeping) {
                            self.setWarnBeforeSleeping()
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Toggle(
                            "Run on Start Up",
                            isOn: $config.runOnStartUp
                        ).onChange(of: config.runOnStartUp) {
                            self.setRunOnStartUp()
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.padding()
                }.overlay(
                        RoundedRectangle(
                            cornerRadius: 5
                        ).stroke(.gray, lineWidth: 1)
                    )
            }
            Text(
                "[Smartfast Labs LLC](https://smartfast.com)"
            )

        }
        .padding([.bottom, .leading, .trailing], 10)
        .padding(.top, 0)
        .clipped()
        .frame(maxWidth: .infinity)
    }

}


#Preview {
    SettingsView(timer: SleepTimer(config: ConfigService()), config: ConfigService())
}
