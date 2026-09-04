# Smart Sleep Timer

macOS menu bar app (SwiftUI, sandboxed, Mac App Store) that puts the Mac to sleep after a countdown or at a configured bedtime.

## Layout
- `SleepTimer/` — app sources, grouped as `App/`, `Models/`, `Services/`, `Views/`, `Support/`. The Xcode project uses synchronized folders, so any file added under `SleepTimer/` or `SleepTimerTests/` is compiled automatically. No project-file edits needed.
- `SleepTimerTests/` — Swift Testing unit tests, hosted in the app.
- `SleepTimer.xcodeproj` — targets `SleepTimer` and `SleepTimerTests`, scheme `SleepTimer`.
- Version lives only in build settings: `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`.

## Architecture
- `Preferences` (`@Observable`) persists settings to UserDefaults; key names are frozen for backward compatibility.
- `SleepScheduler` (`@Observable`, main actor) owns the countdown and bedtime logic. Its clock, sleeper, and activity monitor are injected so tests drive it with `tick()`.
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
