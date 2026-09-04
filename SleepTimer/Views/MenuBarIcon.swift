import AppKit
import SwiftUI

/// The status item image, chosen by scheduler urgency. Images are templates so the
/// system tints them for light mode, dark mode, and the highlighted state.
///
/// Takes the scheduler directly because scene environment values do not reach a
/// `MenuBarExtra` label.
struct MenuBarIcon: View {
    let scheduler: SleepScheduler

    var body: some View {
        Image(nsImage: Self.image(for: scheduler.status))
    }

    private static let pointHeight: CGFloat = 18

    /// Asset catalog names; each is a vector template image.
    static func assetName(for status: SleepScheduler.Status) -> String {
        switch status {
        case .normal: "MenuBarIcon"
        case .pastBedtime: "MenuBarIconPastBedtime"
        case .imminent: "MenuBarIconImminent"
        }
    }

    private static func image(for status: SleepScheduler.Status) -> NSImage {
        guard let source = NSImage(named: assetName(for: status)), let image = source.copy() as? NSImage else {
            return NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Timer")!
        }
        let ratio = image.size.width / image.size.height
        image.size = NSSize(width: pointHeight * ratio, height: pointHeight)
        image.isTemplate = true
        return image
    }
}
