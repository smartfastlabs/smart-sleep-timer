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
    static let windowTitle = "Sleep Countdown"

    private let scheduler: SleepScheduler
    private let preferences: Preferences
    private var window: PromptWindow?
    private var hostingView: NSHostingView<AnyView>?

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
        guard !window.isVisible, let hostingView else { return }
        // Size the window from the content once, here, rather than letting Auto Layout
        // negotiate between the hosting view and the window on every update. Letting it
        // negotiate produced an unbounded update-constraints loop and a crash.
        hostingView.layoutSubtreeIfNeeded()
        window.setContentSize(hostingView.fittingSize)
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

    private func makeWindow() -> PromptWindow {
        let content = AnyView(
            SleepPromptView()
                .environment(scheduler)
                .environment(preferences)
        )
        let hostingView = NSHostingView(rootView: content)
        hostingView.sizingOptions = [.intrinsicContentSize]
        self.hostingView = hostingView

        let window = PromptWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = Self.windowTitle
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        self.window = window
        return window
    }
}

/// A borderless window that still takes keyboard focus, so Return and Escape reach the buttons.
private final class PromptWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
