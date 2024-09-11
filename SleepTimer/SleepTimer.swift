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

func describeInterval(from: Date, to: Date) -> String {
    var elapsed = Int(to.timeIntervalSince(from))
    
    if (elapsed < 0) {
        return "PAST"
    }
    let hours = Int(elapsed / (60 * 60))
    
    elapsed -= hours * 60 * 60
    let minutes = Int(elapsed / 60)
    
    let seconds = elapsed - minutes * 60
    
    if (hours > 0) {
        return "\(String(format: "%02d", hours)):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
    return "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
}

func getWallTime(time: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "hh:mma"
    
    return dateFormatter.string(from: time)
}

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
        
        if (self.getBedTime() < self.currentTime) {
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
        
        if (sleepTime != nil || Date() < self.getBedTime()) {
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
    
    func getBedTime() -> Date {
        return Calendar.current.date(
            bySettingHour: self.config.bedTimeHour,
            minute: self.config.bedTimeMinute,
            second: 0,
            of: Date()
        )!

    }
    
    func clear() {
        self.bedTimeTriggeredAt = nil
        self.sleepTime = nil
        self.warnTime = nil
    }
    
    func shouldStartBedTimeTimer() -> Bool {
        return Calendar.current.date(
                byAdding: .minute,
                value: 60,
                to: Date()
        )! > self.getBedTime()

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
