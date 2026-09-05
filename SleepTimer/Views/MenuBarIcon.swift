import AppKit
import SwiftUI

/// The status item image, chosen by scheduler urgency. Images are templates so the
/// system tints them for light mode, dark mode, and the highlighted state.
///
/// Takes the scheduler directly because scene environment values do not reach a
/// `MenuBarExtra` label. Reads only `status`, which the scheduler stores and updates
/// when it changes, so this view does not re-render on every tick.
struct MenuBarIcon: View {
    let scheduler: SleepScheduler

    var body: some View {
        Image(nsImage: Self.image(for: scheduler.status))
            .accessibilityLabel(Self.accessibilityLabel(for: scheduler.status))
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

    static func accessibilityLabel(for status: SleepScheduler.Status) -> String {
        switch status {
        case .normal: "Sleep Timer"
        case .pastBedtime: "Sleep Timer, past bedtime"
        case .imminent: "Sleep Timer, sleeping soon"
        }
    }

    /// One image per status, built on first use and reused so the status item is not
    /// handed a fresh image on every render.
    private static var cache: [SleepScheduler.Status: NSImage] = [:]

    private static func image(for status: SleepScheduler.Status) -> NSImage {
        if let cached = cache[status] { return cached }
        let image: NSImage
        if let source = NSImage(named: assetName(for: status)), let copy = source.copy() as? NSImage {
            let ratio = copy.size.width / copy.size.height
            copy.size = NSSize(width: pointHeight * ratio, height: pointHeight)
            image = copy
        } else {
            image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: nil)!
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityLabel(for: status)
        cache[status] = image
        return image
    }
}
