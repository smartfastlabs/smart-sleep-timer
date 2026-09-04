import Foundation
import os

/// Unified logging categories. View output with Console.app or:
/// `log stream --predicate 'subsystem == "smartfastlabs.SleepTimer"'`
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "SleepTimer"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let scheduler = Logger(subsystem: subsystem, category: "scheduler")
    static let system = Logger(subsystem: subsystem, category: "system")
}
