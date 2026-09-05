import AppKit

extension NSApplication {
    /// Gives activation back to the app the user was in before we activated, so their
    /// keystrokes do not land nowhere once our window is gone.
    ///
    /// Prefers handing activation directly to `previousApp`; otherwise hides this app,
    /// which makes the system activate whatever is next. Hiding is harmless for a
    /// menu bar app: the status item stays put and any later window unhides it.
    func returnFocus(to previousApp: NSRunningApplication?) {
        if let previousApp, !previousApp.isTerminated, previousApp != .current,
           previousApp.activate(from: .current, options: []) {
            return
        }
        hide(nil)
    }

    /// Returns focus when the last of our windows has closed. Call from a window's
    /// content `onDisappear`; the window itself is still on screen at that moment, so the
    /// check is deferred one turn of the run loop.
    func returnFocusIfNoWindowsRemain() {
        Task { @MainActor in
            let hasWindow = windows.contains { $0.isVisible && $0.canBecomeKey }
            if !hasWindow {
                returnFocus(to: nil)
            }
        }
    }
}
