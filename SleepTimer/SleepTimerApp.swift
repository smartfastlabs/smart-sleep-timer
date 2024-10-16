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

struct WelcomeView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Smart Sleep Timer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your ultimate tool for better sleep.")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Image(nsImage: NSImage(named: "StatusBarIcon")!)
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Smart Sleep Timer runs in the background. Access it anytime from the menu bar.")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("Once you've found Smart Sleep Timer in the Menu Bar click the button below to continue.")
                .font(.body)
                .multilineTextAlignment(.center)
            
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                    
                } label: {
                    Text("I FOUND IT!")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.green)
                Button {
                    guard let url = URL(string: "https://smartfast.com/sleep-timer/support") else { return }
                    openURL(url)
                    
                } label: {
                    Text("I CAN'T FIND IT!")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.red)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
    }
}

var welcomeWindow: NSWindow?

@main
struct SleepTimerApp: App {
    @StateObject var sleepTimer: SleepTimer
    @AppStorage("showWelcome") private var showWelcome = true

    
    private var notificDelegate : NotificationDelegate = NotificationDelegate()
    private var config: ConfigService =  ConfigService()
    
    init(){
        let sleepTimer = SleepTimer(config: config)
        self._sleepTimer = StateObject(wrappedValue: sleepTimer)
        notificDelegate.sleepTimer = sleepTimer
        notificDelegate.addObservers()
        UNUserNotificationCenter.current().delegate = notificDelegate
        if showWelcome {
            print("Show Welcome")
            
            welcomeWindow = NSWindow()
            welcomeWindow?.contentView = NSHostingView(rootView: WelcomeView())
            welcomeWindow?.identifier = NSUserInterfaceItemIdentifier(rawValue: "welcome")
            welcomeWindow?.styleMask = [.closable, .titled]
            welcomeWindow?.isReleasedWhenClosed = true
            welcomeWindow?.center()
            welcomeWindow?.becomeFirstResponder()
            welcomeWindow?.orderFrontRegardless()
            showWelcome = false;
        }
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
