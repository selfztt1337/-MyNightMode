#!/bin/zsh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/MyNightMode.app"
echo "=== macOS ==="
sw_vers
echo "=== developer tools ==="
xcode-select -p 2>&1
swift --version 2>&1
xcrun --sdk macosx --show-sdk-path 2>&1
echo "=== app ==="
if [[ -d "$APP" ]]; then
  find "$APP/Contents" -maxdepth 2 -type f -print
  echo "--- plist ---"
  plutil -p "$APP/Contents/Info.plist" 2>&1
  echo "--- executable ---"
  ls -la "$APP/Contents/MacOS" 2>&1
  file "$APP/Contents/MacOS/MyNightMode" 2>&1
  echo "--- signature ---"
  codesign -dvvv "$APP" 2>&1
  codesign --verify --deep --strict --verbose=4 "$APP" 2>&1
  echo "--- quarantine ---"
  xattr -lr "$APP" 2>&1 || true
  echo "--- launch attempt ---"
  open "$APP" 2>&1
else
  echo "Приложение ещё не собрано."
fi
