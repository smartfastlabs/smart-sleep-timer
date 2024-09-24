//
//  ActivityTracker.swift
//  SleepTimer
//
//  Created by TODD SIFLEET on 9/24/24.
//

import Foundation
import Cocoa

class ActivityTracker: NSObject, NSApplicationDelegate {
    @Published var lastActivity: Date? = nil
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .mouseMoved]) { (event) in
            self.lastActivity = Date()
        }
    }
}
