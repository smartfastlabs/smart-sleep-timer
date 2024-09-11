//
//  Models.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/22/24.
//

import Foundation
import LaunchAtLogin

class ConfigService: ObservableObject {
    @Published var bedTimeEnabled: Bool = false
    @Published var bedTimeHour: Int = 10
    @Published var bedTimeMinute: Int = 0
    @Published var warnBeforeSleeping: Bool = false
    @Published var runOnStartUp: Bool = false
    
    let defaults = UserDefaults.standard
    
    init() {
        self.runOnStartUp = LaunchAtLogin.isEnabled
        self.bedTimeEnabled = defaults.bool(forKey: "bedTimeEnabled")
        self.warnBeforeSleeping = defaults.bool(forKey: "warnBeforeSleeping")
        self.bedTimeHour = defaults.integer(forKey: "bedTimeHour")
        if (self.bedTimeHour == 0) {
            self.bedTimeHour = 10
        }
        self.bedTimeMinute = defaults.integer(forKey: "bedTimeMinute")
    }
    
    func set(
        bedTimeEnabled: Bool? = nil,
        warnBeforeSleeping: Bool? = nil,
        bedTimeHour: Int? = nil,
        bedTimeMinute: Int? = nil,
        runOnStartUp: Bool? = nil
    ) {
        if (bedTimeEnabled != nil) {
            self.bedTimeEnabled = bedTimeEnabled!
            defaults.set(bedTimeEnabled, forKey: "bedTimeEnabled")
        }
        if (warnBeforeSleeping != nil) {
            self.warnBeforeSleeping = warnBeforeSleeping!
            defaults.set(warnBeforeSleeping, forKey: "warnBeforeSleeping")
        }
        if (bedTimeHour != nil) {
            self.bedTimeHour = bedTimeHour!
            defaults.set(bedTimeHour, forKey: "bedTimeHour")
        }
        if (bedTimeMinute != nil) {
            self.bedTimeMinute = bedTimeMinute!
            defaults.set(bedTimeMinute, forKey: "bedTimeMinute")
        }
        if (runOnStartUp != nil) {
            LaunchAtLogin.isEnabled = runOnStartUp!
            self.runOnStartUp = runOnStartUp!
        }
    }
}
