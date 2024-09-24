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
    @NSApplicationDelegateAdaptor(ActivityTracker.self) var appDelegate
    var showMenuBar: Bool = true
    
    private var notificDelegate : NotificationDelegate = NotificationDelegate()
    private var config: ConfigService =  ConfigService()
    init(){
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
            
            let bedTime = self.sleepTimer.getBedTime()
            let iconName = if (self.sleepTimer.willSleepIn(minutes: 30)){
                "StatusBarDangerIcon"
            } else if (bedTime != nil && bedTime! < Date()) {
                "StatusBarAlertIcon"
            } else {
                "StatusBarIcon"
            }
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 20
                $0.size.width = 20 / ratio
                return $0
            }(NSImage(named: iconName)!)
            
            Image(nsImage: image)
        }.menuBarExtraStyle(.window)
    }
}
