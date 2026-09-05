import AppKit
import Observation
import SwiftUI
import os

/// Shows the full-screen countdown overlay whenever the scheduler has a pending sleep,
/// and hides it otherwise.
///
/// Uses AppKit directly because the overlay must cover the screen, float above everything,
/// appear on every Space including full-screen apps, and open without any view on screen
/// to trigger it.
@MainActor
final class SleepPromptPresenter {
    static let windowTitle = "Sleep Countdown"

    private let scheduler: SleepScheduler
    private let preferences: Preferences
    private var window: PromptWindow?
    /// The app that was frontmost before the overlay took over, so focus can go back.
    private var previousApp: NSRunningApplication?

    var isShowingWindow: Bool {
        window?.isVisible ?? false
    }

    /// For diagnostics and tests.
    var windowFrame: NSRect? {
        window?.frame
    }

    init(scheduler: SleepScheduler, preferences: Preferences) {
        self.scheduler = scheduler
        self.preferences = preferences
        observe()
    }

    /// Re-registers observation after every change, the standard `withObservationTracking` loop.
    private func observe() {
        withObservationTracking {
            if scheduler.pendingSleep != nil {
                show()
            } else {
                hide()
            }
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observe()
            }
        }
    }

    private func show() {
        let window = self.window ?? makeWindow()
        guard !window.isVisible else { return }
        // Cover the screen the user is working on. The window is sized here, explicitly,
        // rather than by Auto Layout negotiating with the hosting view, which looped.
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let screen {
            window.setFrame(screen.frame, display: false)
        }
        previousApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        Log.app.info("Sleep prompt shown")
    }

    private func hide() {
        guard let window, window.isVisible else { return }
        window.orderOut(nil)
        NSApp.returnFocus(to: previousApp)
        previousApp = nil
        Log.app.info("Sleep prompt hidden")
    }

    private func makeWindow() -> PromptWindow {
        let content = SleepPromptView()
            .environment(scheduler)
            .environment(preferences)
        let hostingView = NSHostingView(rootView: content)
        // The overlay fills whatever frame the window is given; it has no size of its own.
        hostingView.sizingOptions = []

        let window = PromptWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = Self.windowTitle
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        self.window = window
        return window
    }
}

/// A borderless window that still takes keyboard focus, so Return reaches the buttons.
private final class PromptWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
