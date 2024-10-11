//
//  SleepTimerApp.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//


import SwiftUI
import UserNotifications


class SleepTimer: ObservableObject {
    @Published var sleepTime: Date? = nil
    @Published var currentTime: Date
    
    var bedTimeTriggeredAt: Date? = nil
    
    var timer: Timer? = nil
    var config: ConfigService
    var lastMousePosition: NSPoint
    var lastActivity: Date = Date()
    
    init(config: ConfigService) {
        self.currentTime = Date()
        self.config = config
        self.lastMousePosition = NSEvent.mouseLocation
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.currentTime = Date()
            if (self.lastMousePosition != NSEvent.mouseLocation) {
                self.lastMousePosition = NSEvent.mouseLocation
                self.handleActivity()
            }
            if (self.shouldTriggerBedTime()) {
                self.bedTimeTriggeredAt = Date()
                print("BED TIME")
                self.goToSleep()
            } else if (self.sleepTime != nil && Date() > self.sleepTime!) {
                print("SLEEP TIMER")
                self.goToSleep()
                self.clear()
            }
        })
        
        let bedTime = self.getBedTime()
        if (bedTime != nil && bedTime! < self.currentTime) {
            self.bedTimeTriggeredAt = Date()
        }

        let doneAction = UNNotificationAction(
            identifier: "sleepTimeReminder.doneAction",
            title: "Done",
            options: []
        )
        let tenMoreMinutesAction = UNNotificationAction(
            identifier: "sleepTimeReminder.tenMoreMinutesAction",
            title: "10 More Minutes",
            options: []
        )
        
        let sleepTimerCategory = UNNotificationCategory(
            identifier: "sleepTimeReminder",
            actions: [doneAction, tenMoreMinutesAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([sleepTimerCategory])
    }
    deinit {
        timer?.invalidate()
    }
   
    func goToSleep() {
        if (self.lastActivity.distance(to: Date()) > 60 * 2) {
            sleep()
        }
    }
    
    func handleActivity() {
        self.lastActivity = Date()
        print("handleActivity")
        
    }
    
    func shouldTriggerBedTime() -> Bool {
        if (alreadyWentToSleepToday()) {
            return false
        }
        
        if (sleepTime != nil) {
            return false
        }
        
        let bedTime = self.getBedTime()
        if (bedTime == nil || Date() < bedTime!) {
            return false
        }
        
        return true
    }
    
    func alreadyWentToSleepToday() -> Bool {
        if (bedTimeTriggeredAt == nil) {
            return false
        }
        
        return Calendar.current.isDate(
            bedTimeTriggeredAt!,
            equalTo: Date(),
            toGranularity: .day
        )
    }
    
    
    func getNextSleepTime() -> Date? {
        if (self.sleepTime != nil) {
            return self.sleepTime!
        }
        if (self.config.bedTimeEnabled && !self.alreadyWentToSleepToday()) {
            return getBedTime()
        }
        return nil
    }
    
    func getBedTime() -> Date? {
        return Calendar.current.date(
            bySettingHour: self.config.bedTimeHour,
            minute: self.config.bedTimeMinute,
            second: 0,
            of: Date()
        )!
        
    }
    
    func clear() {
        let bedTime = self.getBedTime()
        if (bedTime == nil || bedTime! > Date()) {
            self.bedTimeTriggeredAt = nil
        }
        self.sleepTime = nil
    }
    
    func willSleepIn(minutes: Int) -> Bool {
        let nextSleepTime = getNextSleepTime()
        if (nextSleepTime == nil) {
            return false
        }
        return Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date()
        )! > nextSleepTime!
        
    }
    
    func setSleepInterval(minutes: Int) {
        self.config.set(sleepIntervalMinutes: minutes)
        
        if (minutes > 0) {
            return self.setSleepTime(minutes: minutes)
        } else {
            return self.clear()
        }
    }
    
    func setSleepTime(minutes: Int) {
        self.sleepTime = Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date()
        )!
        
    }
}
