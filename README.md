<p align="center">
  <img src="docs/screenshots/hero.png" alt="Smart Sleep Timer" width="1000">
</p>

<p align="center">
  <a href="https://apps.apple.com/us/app/smart-sleep-timer/id6717561931?mt=12"><img src="https://img.shields.io/badge/Mac_App_Store-Download-0D96F6?logo=apple&logoColor=white" alt="Download on the Mac App Store"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-000000?logo=apple&logoColor=white" alt="macOS 15 or later">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/SwiftUI-native-0D96F6" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-blue" alt="AGPL-3.0"></a>
</p>

**Smart Sleep Timer** is a tiny menu bar app that puts your Mac to sleep when you mean to stop. Set a timer before you start a show. Give yourself a bedtime. Turn on Lights Out and your Mac keeps going back to sleep until morning. If you're still typing when time's up, it asks first.

No accounts. No network. No tracking. It's sandboxed, it runs from the menu bar, and it does one thing.

<p align="center">
  <a href="https://apps.apple.com/us/app/smart-sleep-timer/id6717561931?mt=12"><b>Get it on the Mac App Store →</b></a>
</p>

---

## Quick timers from the menu bar

Click the moon, pick 15 minutes to 2 hours, and forget about it. The popover shows exactly when your Mac will sleep.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/popover-dark.png">
    <img src="docs/screenshots/popover-light.png" alt="The menu bar popover with a 30-minute timer running" width="360">
  </picture>
</p>

## It asks before it acts

If you've touched the keyboard or mouse in the last couple of minutes when a timer ends, your Mac doesn't just vanish under you. A full-screen countdown gives you ten seconds and four choices. Left alone, it sleeps.

<p align="center">
  <img src="docs/screenshots/overlay.png" alt="The full-screen countdown: Time for bed, with 15 more minutes, 30 more minutes, 1 more hour, and Not tonight" width="1000">
</p>

If you've stepped away, there's no countdown at all. Your Mac sleeps silently, which is the whole point.

## Bedtime

Set a bedtime and a wake time. When bedtime arrives, your Mac goes to sleep, or shows the countdown if you're mid-sentence. Bedtime lasts until wake time, so 10 PM to 6 AM is one night, and midnight doesn't confuse it.

## Lights Out

The feature for people who wake the Mac back up at 1 AM "just to check something." Between bedtime and wake time, Lights Out puts the Mac back to sleep a set number of minutes after every wake. Fifteen minutes by default. Snoozing buys you another round. **Not tonight** on the countdown turns it off until morning, and the popover shows a Resume button in case you change your mind.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/popover-lightsout-dark.png">
    <img src="docs/screenshots/popover-lightsout-light.png" alt="The popover during Lights Out, counting down to the next sleep" width="360">
  </picture>
</p>

## The icon tells you what's coming

<p align="center">
  <img src="docs/screenshots/menubar.png" alt="Menu bar icon states: outline when idle, filled when sleeping within 30 minutes, filled with a dot past bedtime" width="600">
</p>

## Settings

Everything lives in one window. Bedtime and wake time, Lights Out and its interval, how long you have to be idle before the Mac sleeps without asking, and open at login.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/settings-dark.png">
    <img src="docs/screenshots/settings-light.png" alt="The Settings window" width="420">
  </picture>
</p>

## Privacy

Smart Sleep Timer makes no network connections and collects nothing. It reads how long you've been idle from the system, which needs no special permission, and puts the Mac to sleep with the same command the `pmset` tool uses. It runs inside the macOS App Sandbox.

## Requirements

macOS 15 Sequoia or later, Apple silicon or Intel.

---

## Building from source

The app is a plain Xcode project with no dependencies.

```bash
git clone https://github.com/smartfastlabs/smart-sleep-timer.git
cd smart-sleep-timer
open SleepTimer.xcodeproj
```

Press Run. To build and test from the terminal:

```bash
xcodebuild -project SleepTimer.xcodeproj -scheme SleepTimer -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```

### How it's put together

- `SleepTimer/Models` holds the logic: `SleepScheduler` is the state machine that decides when to sleep, `BedtimeSchedule` is the window math, and `Preferences` persists settings.
- `SleepTimer/Services` talks to the system: idle time, sleeping, and the login item.
- `SleepTimer/Views` is SwiftUI. The countdown overlay is the one piece of AppKit, because it has to float above full-screen apps.
- `SleepTimerTests` drives the scheduler with a fake clock, renders every view to catch wiring mistakes, and generates the screenshots on this page from the real views. Run `Scripts/screenshots.sh` to regenerate them.

## Contributing

Issues and pull requests are welcome. If you're changing behavior, add a scheduler test; they're short and they run in under a second.

## License

[AGPL-3.0](LICENSE). Made by [Smartfast Labs](https://smartfast.com).
