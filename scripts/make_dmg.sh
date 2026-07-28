#!/bin/zsh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")"; APP="$ROOT/dist/NightMode.app"; DMG="$ROOT/dist/NightMode-$VERSION.dmg"; [[ -d "$APP" ]] || "$ROOT/scripts/build_app.sh"
rm -f "$DMG"; hdiutil create -volname "NightMode" -srcfolder "$APP" -ov -format UDZO "$DMG"; echo "✅ $DMG"; open "$ROOT/dist"
