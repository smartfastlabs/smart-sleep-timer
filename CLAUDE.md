# Smart Sleep Timer

macOS menu bar app (SwiftUI, sandboxed, Mac App Store) that puts the Mac to sleep after a countdown or at a configured bedtime.

## Layout
- `SleepTimer/` — app sources, grouped as `App/`, `Models/`, `Services/`, `Views/`, `Support/`. The Xcode project uses synchronized folders, so any file added under `SleepTimer/` or `SleepTimerTests/` is compiled automatically. No project-file edits needed.
- `SleepTimerTests/` — Swift Testing unit tests, hosted in the app.
- `SleepTimer.xcodeproj` — targets `SleepTimer` and `SleepTimerTests`, scheme `SleepTimer`.
- Version lives only in build settings: `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`.

## Architecture
- `Preferences` (`@Observable`) persists settings to UserDefaults; key names are frozen for backward compatibility.
- `SleepScheduler` (`@Observable`, main actor) is the state machine: countdown, bedtime, Lights Out, and the sleep prompt. Its clock, sleeper, and activity monitor are injected so tests drive it with `tick()` via `SchedulerHarness` in the test target. The rules are listed in its doc comment.
- `BedtimeSchedule` is the pure date math for the nightly window (half-open, may cross midnight). Bedtime fires once per window; launching, waking, or sleeping inside the window counts it as handled. Lights Out re-arms a countdown inside the window whenever no countdown is running.
- `scheduler.now` changes every second and every derived property reads it, so a view that touches the scheduler re-renders each tick. That's fine for the popover. Views that must not re-render each tick (the menu bar icon) read only `scheduler.status`, which is stored and assigned only on change.
- When a sleep comes due, the scheduler sleeps immediately if the user has been idle past the threshold; otherwise it sets `pendingSleep` and `SleepPromptPresenter` shows the full-screen overlay via `withObservationTracking`. The overlay window is sized explicitly, never by Auto Layout, after a constraint loop crash.
- This is a menu bar app with no Dock presence, so whenever our last window closes we hand activation back (`NSApplication.returnFocus`), or the user's keystrokes land nowhere.
- `SnapshotTests` render every view to PNG under the temp directory on each run. They are review artifacts, not assertions; look at them after UI changes.
- `SystemActivityMonitor` reads idle time from `CGEventSource`; `PMSetSleeper` runs `pmset sleepnow`; `LoginItem` wraps `SMAppService`.
- Views get models via `.environment(...)`. Apply it inside the `MenuBarExtra` content closure, not on the scene: scene-level environment reaches neither the content nor the label. `MenuBarIcon` takes the scheduler as a plain property for the same reason.

## Build and test
```bash
xcodebuild -project SleepTimer.xcodeproj -scheme SleepTimer -configuration Debug CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E 'error:|warning:|BUILD'
```
```bash
xcodebuild -project SleepTimer.xcodeproj -scheme SleepTimer -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test 2>&1 | grep -E 'error:|Test case|TEST'
```
Run the build after every meaningful change and the tests before every commit. Warnings count as failures; keep the build clean. Note that `xcodebuild test` launches the real app as the test host, so a menu bar icon appears briefly.

## Conventions
- Minimum macOS 15. Use `#available(macOS 26, *)` for newer polish.
- Swift 6 language mode, main-actor isolated UI, `@Observable` models, `os.Logger` instead of `print`.
- No third-party dependencies unless there is no first-party API.
- Commit per logical step with a short imperative subject line.

## Roles
Claude edits and builds from the terminal. Xcode is for SwiftUI previews, signing, archiving, and App Store upload.
