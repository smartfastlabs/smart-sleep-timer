//
//  SleepTimerApp.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 8/21/24.
//


import SwiftUI
import UserNotifications
/*
 TODO:
 1) Maybe have an option to disable sleep: https://www.hackingwithswift.com/forums/macos/have-app-prevent-computer-going-to-sleep/23419
 */

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
    
    @objc private func sleepListener(_ aNotification: Notification) {
        print("listening to sleep")
        if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")
        } else if aNotification.name == NSWorkspace.didWakeNotification {
            if (self.sleepTimer != nil ) {
                self.sleepTimer!.handleActivity()
            }
            print("Woke up")
        } else {
            print("Some other event other than the first two")
        }
    }
    
    func addObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                          name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                          name: NSWorkspace.didWakeNotification, object: nil)
    }
}

struct MenuBarIcon: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var sleepTimer: SleepTimer
   
    var body: some View {
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
        }(NSImage(named: colorScheme == .light ? iconName: "\(iconName)White")!)
        
        Image(nsImage: image)
    }
}

@main
struct SleepTimerApp: App {
    @StateObject var sleepTimer: SleepTimer
    
    private var notificDelegate : NotificationDelegate = NotificationDelegate()
    private var config: ConfigService =  ConfigService()
    
    init(){
        let sleepTimer = SleepTimer(config: config)
        self._sleepTimer = StateObject(wrappedValue: sleepTimer)
        notificDelegate.sleepTimer = sleepTimer
        notificDelegate.addObservers()
        UNUserNotificationCenter.current().delegate = notificDelegate
    }
    
    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            TimerView(timer: self.sleepTimer)
            
            SettingsView(timer: sleepTimer, config: config)
        } label: {
            
            MenuBarIcon(sleepTimer: self.sleepTimer)
        }.menuBarExtraStyle(.window)
    }
}
