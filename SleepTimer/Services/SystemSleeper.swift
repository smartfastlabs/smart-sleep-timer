import Foundation
import os

/// Puts the Mac to sleep.
protocol SystemSleeping {
    func sleep()
}

/// Sleeps the Mac by running `pmset sleepnow`, which works from a sandboxed app
/// without elevated privileges.
struct PMSetSleeper: SystemSleeping {
    func sleep() {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/pmset")
        process.arguments = ["sleepnow"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            Log.system.info("Requested system sleep")
        } catch {
            Log.system.error("Could not run pmset: \(error.localizedDescription, privacy: .public)")
        }
    }
}
