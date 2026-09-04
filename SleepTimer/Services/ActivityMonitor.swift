import CoreGraphics
import Foundation

/// Reports how long the user has been idle.
protocol ActivityMonitoring {
    /// Seconds since the user last pressed a key, moved the mouse, or otherwise provided input.
    func secondsSinceLastInput() -> TimeInterval
}

/// Reads idle time from the window server. Works inside the App Sandbox and needs no
/// Accessibility permission because it never observes the events themselves.
struct SystemActivityMonitor: ActivityMonitoring {
    /// `kCGAnyInputEventType` from CGEventSource.h, which Swift does not import.
    /// Falls back to mouse movement only if the raw value is ever rejected.
    private static let anyInput = CGEventType(rawValue: ~0) ?? .mouseMoved

    func secondsSinceLastInput() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: Self.anyInput)
    }
}
