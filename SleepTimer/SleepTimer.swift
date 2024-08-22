//
//  SleepTimerApp.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//


import SwiftUI
import UserNotifications

@discardableResult func sleep() -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", "pmset sleepnow"]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

func warn(minutes: Int) {
    let content = UNMutableNotificationContent()
    content.title = "Time to Go To Sleep"
    content.subtitle = "Your computer will go to sleep in \(minutes) minute."
    content.sound = UNNotificationSound.default
    content.categoryIdentifier = "sleepTimeReminder"


    // choose a random identifier
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

    // add our notification request
    UNUserNotificationCenter.current().add(request)
}

func humanIntervalFromNow(input: Date?) -> String {
    if (input == nil) {
        return "NA"
    }
    var elapsed = Int(input!.timeIntervalSince(Date.now))
    
    let hours = Int(elapsed / (60 * 60))
    
    elapsed -= hours * 60 * 60
    let minutes = Int(elapsed / 60)
    
    let seconds = elapsed - minutes * 60
    
    if (hours > 0) {
        return "\(String(format: "%02d", hours)):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
    return "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
}

class SleepTimer: ObservableObject {
    @Published var sleepTime: Date? = nil
    @Published var warnTime: Date? = nil

    
    
    @Published var bedTimeEnabled: Bool = false
    @Published var bedTimeHour: Int = 1
    @Published var bedTimeMinute: Int = 0
    @Published var bedTimeAmPm: String = "PM"
    
    @Published var nextSleepTime: Date? = nil
    @Published var humanReadable: String? = nil
    
    let defaults = UserDefaults.standard
    var bedTimeTriggered: Bool = false
    
    var timer: Timer?
    init() {
        self.bedTimeEnabled = defaults.bool(forKey: "bedTimeEnabled")
        self.bedTimeHour = defaults.integer(forKey: "bedTimeHour")
        if (self.bedTimeHour == 0) {
            self.bedTimeHour = 10
        }
        self.bedTimeMinute = defaults.integer(forKey: "bedTimeMinute")
        self.bedTimeAmPm = defaults.string(forKey: "bedTimeAmPm") ?? "PM"
        
        self.nextSleepTime = self.getSleepAt()
        self.humanReadable = self.nextSleepTime != nil ? humanIntervalFromNow(input: nextSleepTime): nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if (self.sleepTime == nil && !self.bedTimeTriggered && self.bedTimeEnabled && self.isAfterBedTime()) {
                self.bedTimeTriggered = true
                sleep()
                return
            }
            self.nextSleepTime = self.getSleepAt()
            self.humanReadable = self.nextSleepTime != nil ? humanIntervalFromNow(input: self.nextSleepTime): nil
            if (self.sleepTime != nil) {
                if (Date() > self.sleepTime!) {
                    sleep()
                    self.clear()
                }
            }
            if (self.warnTime != nil && Date() > self.warnTime!) {
                self.warnTime = nil
                warn(minutes: 2)
            }
        })
        
        let doneAction = UNNotificationAction(identifier: "sleepTimeReminder.doneAction", title: "Done", options: [])
        let tenMoreMinutesAction = UNNotificationAction(identifier: "sleepTimeReminder.tenMoreMinutesAction", title: "10 More Minutes", options: [])

        let sleepTimerCategory = UNNotificationCategory(
            identifier: "sleepTimeReminder",
            actions: [doneAction, tenMoreMinutesAction],
            intentIdentifiers: [],
            options: .customDismissAction)

        UNUserNotificationCenter.current().setNotificationCategories([sleepTimerCategory])
    }
    deinit {
        timer?.invalidate()
    }
    
    func isAfterBedTime() -> Bool {
        print(self.getBedTime())
        return Date() > self.getBedTime()
    }
    
    func getSleepAt() -> Date? {
        if (self.sleepTime != nil) {
            return self.sleepTime!
        }
        if (self.bedTimeEnabled) {
            return getBedTime()
        }
        return nil
    }
    
    func getBedTime() -> Date {
        return Calendar.current.date(
            bySettingHour: self.bedTimeAmPm == "PM" ? self.bedTimeHour + 12 : self.bedTimeHour,
            minute: self.bedTimeMinute,
            second: 0,
            of: Date()
        )!

    }
    
    func clear() {
        self.bedTimeTriggered = false
        self.sleepTime = nil
        self.warnTime = nil
        self.nextSleepTime = self.getSleepAt()
        self.humanReadable = self.nextSleepTime != nil ? humanIntervalFromNow(input: self.nextSleepTime): nil
    }
    
    func saveBedTime() {
        if (self.getBedTime() > Date()) {
            self.bedTimeTriggered = false
        }
        let defaults = UserDefaults.standard
        defaults.set(bedTimeEnabled, forKey: "bedTimeEnabled")
        defaults.set(bedTimeHour, forKey: "bedTimeHour")
        defaults.set(bedTimeMinute, forKey: "bedTimeMinute")
        defaults.set(bedTimeAmPm, forKey: "bedTimeAmPm")
    }
    
    func setSleepTime(minutes: Int) {
        self.sleepTime = Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date()
        )!
        self.nextSleepTime = self.getSleepAt()
        self.humanReadable = self.nextSleepTime != nil ? humanIntervalFromNow(input: nextSleepTime): nil
        self.warnTime = Calendar.current.date(
            byAdding: .minute,
            value: minutes - 2,
            to: Date()
        )!
    }
}
