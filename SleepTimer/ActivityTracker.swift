//
//  ActivityTracker.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 9/24/24.
//

import Foundation
import Cocoa

class ActivityTracker: NSObject, NSApplicationDelegate {
    @Published var lastActivity: Date = Date()
    
    var lastMousePosition: NSPoint?
    var timer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // NOTE: It seems like we can't track keyDown/keyUp with the sandbox enabled
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { (event) in
            self.lastActivity = Date()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in
            if (self.lastMousePosition != NSEvent.mouseLocation) {
                self.lastMousePosition = NSEvent.mouseLocation
                self.lastActivity = Date()
            }
        })
    }
}
