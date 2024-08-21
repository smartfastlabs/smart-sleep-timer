//
//  SleepTimerApp.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//


import SwiftUI
import UserNotifications

func sleep() -> String {
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

func minutesToClock(input: Int) -> String {
    if (input < 60) {
        return "\(input)m"
    }
    
    let hours = input / 60
    let minutes = input - hours * 60
    if (hours == 0) {
        return "\(minutes)m"
    } else if (minutes == 0) {
        return "\(hours)h"
    }
    return "\(hours)h \(minutes)m"
}


func minutesToEnglish(input: Int) -> String {
    if (input < 60) {
        return "\(input) minutes"
    }
    
    let hours = input / 60
    let minutes = input - hours * 60
    if (minutes < 15) {
        return "\(hours) hours"
    }
    if (minutes < 45) {
        return "\(hours).5 hours"
    }
    
    return "\(hours + 1) hours"
}
func minutesUntil(time: Date) -> Int {
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())

    return calendar.dateComponents([.minute], from: nowComponents, to: timeComponents).minute!
}

class SleepTimer: ObservableObject {
    @Published var sleepTime: Date? = nil
    @Published var warnTime: Date? = nil
    @Published var minutesUntilSleep: Int? = nil
    
    @Published var bedTimeEnabled: Bool = false
    @Published var bedTimeHour: Int = 1
    @Published var bedTimeMinute: Int = 0
    @Published var bedTimeAmPm: String = "PM"
    
    let defaults = UserDefaults.standard
    
    var timer: Timer?
    init() {
        self.bedTimeEnabled = defaults.bool(forKey: "bedTimeEnabled")
        self.bedTimeHour = defaults.integer(forKey: "bedTimeHour")
        if (self.bedTimeHour == 0) {
            self.bedTimeHour = 10
        }
        self.bedTimeMinute = defaults.integer(forKey: "bedTimeMinute")
        self.bedTimeAmPm = defaults.string(forKey: "bedTimeAmPm") ?? "PM"
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if (self.sleepTime != nil) {
                self.minutesUntilSleep = minutesUntil(time: self.sleepTime!)
                if (Date() > self.sleepTime!) {
                    self.clear()
                    print(sleep())
                }
            }
            if (self.warnTime != nil && Date() > self.warnTime!) {
                self.warnTime = nil
                warn(minutes: 2)
            }
            print("TIMER SLEEP TIME", self.sleepTime)
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
    
    func clear() {
        self.minutesUntilSleep = nil
        self.sleepTime = nil
        self.warnTime = nil
    }
    
    func saveBedTime() {
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
        
        self.minutesUntilSleep = minutesUntil(time: self.sleepTime!)
        
        self.warnTime = Calendar.current.date(
            byAdding: .minute,
            value: minutes - 2,
            to: Date()
        )!
    }
    
    func snooze(minutes: Int) {
        setSleepTime(minutes: minutesUntilSleep! + minutes)
    }
}
