#!/bin/zsh
# Regenerates docs/screenshots/ from the app's real views via ReadmeScreenshots tests.
set -euo pipefail
setopt null_glob
cd "$(dirname "$0")/.."

OUT="$(getconf DARWIN_USER_TEMP_DIR)SleepTimerSnapshots/readme"
rm -rf "$OUT"

xcodebuild -project SleepTimer.xcodeproj -scheme SleepTimer -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO -only-testing:SleepTimerTests/ReadmeScreenshots test 2>&1 \
  | grep -E 'error:|TEST (SUCCEEDED|FAILED)' || true

mkdir -p docs/screenshots
rm -f docs/screenshots/*.png
cp "$OUT"/*.png docs/screenshots/

# The wide images are rendered at 2x; README shows them at 1000px, so 1600px is plenty.
for wide in hero overlay; do
  sips --resampleWidth 1600 "docs/screenshots/$wide.png" >/dev/null
done

echo "Wrote:"
ls -l docs/screenshots | awk 'NR>1 {printf "%7.0f KB  %s\n", $5/1024, $9}'
