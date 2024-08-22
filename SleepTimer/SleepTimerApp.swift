//
//  SleepTimerApp.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//


import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject , UNUserNotificationCenterDelegate{
    var sleepTimer: SleepTimer?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "sleepTimeReminder.tenMoreMinutesAction":
            self.sleepTimer!.setSleepTime(minutes: 10)
        default:
            break
        }
        completionHandler()
    }
}



@main
struct SleepTimerApp: App {
    @StateObject var sleepTimer: SleepTimer
    
    private var notificDelegate : NotificationDelegate = NotificationDelegate()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(){
        let sleepTimer = SleepTimer()
        self._sleepTimer = StateObject(wrappedValue: sleepTimer)
        notificDelegate.sleepTimer = sleepTimer
        UNUserNotificationCenter.current().delegate = notificDelegate
    }

    var body: some Scene {
        MenuBarExtra() {
                TimerView(timer: self.sleepTimer)
        } label: {
            HStack {
                Image(systemName: "moon.zzz.fill")
                // This was causing crashes on my laptop
//                if (sleepTimer.sleepTime != nil) {
//                    Text(sleepTimer.timeUntilSleepTime)
//                }
            }

        }.menuBarExtraStyle(.window)
    }
}
