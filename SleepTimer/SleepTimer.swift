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
    @Published var warnTime: Date? = nil
    @Published var currentTime: Date
    
    let defaults = UserDefaults.standard
    var bedTimeTriggeredAt: Date? = nil
    
    var timer: Timer?
    var config: ConfigService
    
    init(config: ConfigService) {
        self.currentTime = Date()
        self.config = config
        
        let bedTime = self.getBedTime()
        if (bedTime != nil && bedTime! < self.currentTime) {
            self.bedTimeTriggeredAt = Date()
        }
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.currentTime = Date()
            if (self.shouldTriggerBedTime()) {
                self.bedTimeTriggeredAt = Date()
                print("BED TIME")
                sleep()
            } else if (self.sleepTime != nil && Date() > self.sleepTime!) {
                print("SLEEP TIMER")
                sleep()
                self.clear()
            } else if (self.config.warnBeforeSleeping && self.warnTime != nil && Date() > self.warnTime!) {
                print("WARNING")
                self.warnTime = nil
                warn(minutes: 2)
            }
        })
        
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
        self.warnTime = nil
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
    
    func setSleepTime(minutes: Int) {
        self.sleepTime = Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date()
        )!
        
        self.warnTime = Calendar.current.date(
            byAdding: .minute,
            value: minutes - 2,
            to: Date()
        )!
    }
}
