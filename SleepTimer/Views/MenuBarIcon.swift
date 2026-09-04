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

    private static func image(for status: SleepScheduler.Status) -> NSImage {
        let name = switch status {
        case .normal: "StatusBarIcon"
        case .pastBedtime: "StatusBarAlertIcon"
        case .imminent: "StatusBarDangerIcon"
        }
        guard let source = NSImage(named: name), let image = source.copy() as? NSImage else {
            return NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Sleep Timer")!
        }
        let ratio = image.size.width / image.size.height
        image.size = NSSize(width: pointHeight * ratio, height: pointHeight)
        image.isTemplate = true
        return image
    }
}
