import AppKit
import Observation
import SwiftUI
import os

/// Shows the countdown panel whenever the scheduler has a pending sleep, and hides it otherwise.
///
/// Uses AppKit directly because the panel must float above everything, appear on every Space
/// including full-screen apps, and open without any view being on screen to trigger it.
@MainActor
final class SleepPromptPresenter {
    private let scheduler: SleepScheduler
    private let preferences: Preferences
    private var window: NSWindow?

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
        self.window = window
        guard !window.isVisible else { return }
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        Log.app.info("Sleep prompt shown")
    }

    private func hide() {
        guard let window, window.isVisible else { return }
        window.orderOut(nil)
        Log.app.info("Sleep prompt hidden")
    }

    private func makeWindow() -> NSWindow {
        let content = SleepPromptView()
            .environment(scheduler)
            .environment(preferences)
        let controller = NSHostingController(rootView: content)
        controller.sizingOptions = [.preferredContentSize]

        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        return window
    }
}
