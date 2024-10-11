//
//  Utils.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 9/23/24.
//

import Foundation
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
    
//    content.i
    content.subtitle = "Your computer will go to sleep in \(minutes) minutes."
    content.sound = UNNotificationSound.default
    content.categoryIdentifier = "sleepTimeReminder"
    
    
    // choose a random identifier
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    
    // add our notification request
    UNUserNotificationCenter.current().add(request)
}

func describeInterval(from: Date, to: Date) -> String {
    var elapsed = Int(from.distance(to: to))
    
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
