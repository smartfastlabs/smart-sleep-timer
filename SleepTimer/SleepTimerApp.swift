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
    var showMenuBar: Bool = true
    
    private var notificDelegate : NotificationDelegate = NotificationDelegate()
    private var config: ConfigService =  ConfigService()
    init(){
        //    https://github.com/thompsonate/Shifty/blob/master/Shifty/CBBlueLightClient.h
        let sleepTimer = SleepTimer(config: config)
        self._sleepTimer = StateObject(wrappedValue: sleepTimer)
        notificDelegate.sleepTimer = sleepTimer
        UNUserNotificationCenter.current().delegate = notificDelegate
    }

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            TimerView(timer: self.sleepTimer)

            SettingsView(timer: sleepTimer, config: config)
        } label: {
            HStack {
                Image(systemName: "moon.zzz.fill")
            }

        }.menuBarExtraStyle(.window)
    }
}
