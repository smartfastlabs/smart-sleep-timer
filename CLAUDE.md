# Smart Sleep Timer

macOS menu bar app (SwiftUI, sandboxed, Mac App Store) that puts the Mac to sleep after a countdown or at a configured bedtime.

## Layout
- `SleepTimer/` — all app sources. The Xcode project uses a synchronized folder, so any file added here is compiled automatically. No project-file edits needed.
- `SleepTimer.xcodeproj` — single target `SleepTimer`, scheme `SleepTimer`.
- Version lives only in build settings: `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`.

## Build and test
```bash
xcodebuild -project SleepTimer.xcodeproj -scheme SleepTimer -configuration Debug CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E 'error:|warning:|BUILD'
```
Run the build after every meaningful change. Warnings count as failures; keep the build clean.

## Conventions
- Minimum macOS 15. Use `#available(macOS 26, *)` for newer polish.
- Swift 6 language mode, main-actor isolated UI, `@Observable` models, `os.Logger` instead of `print`.
- No third-party dependencies unless there is no first-party API.
- Commit per logical step with a short imperative subject line.

## Roles
Claude edits and builds from the terminal. Xcode is for SwiftUI previews, signing, archiving, and App Store upload.
