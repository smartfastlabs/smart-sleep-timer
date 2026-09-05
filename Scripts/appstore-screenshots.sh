#!/bin/zsh
# Regenerates docs/appstore/screenshots/ (2880×1800 PNGs for App Store Connect)
# from the app's real views via the AppStoreScreenshots tests.
set -euo pipefail
setopt null_glob
cd "$(dirname "$0")/.."

OUT="$(getconf DARWIN_USER_TEMP_DIR)SleepTimerSnapshots/appstore"
rm -rf "$OUT"

xcodebuild -project SleepTimer.xcodeproj -scheme SleepTimer -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO -only-testing:SleepTimerTests/AppStoreScreenshots test 2>&1 \
  | grep -E 'error:|TEST (SUCCEEDED|FAILED)' || true

mkdir -p docs/appstore/screenshots
rm -f docs/appstore/screenshots/*.png
cp "$OUT"/*.png docs/appstore/screenshots/

echo "Wrote:"
for f in docs/appstore/screenshots/*.png; do
  printf '%s  %s\n' "$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/ {printf "%s ", $2}')" "$f"
done
