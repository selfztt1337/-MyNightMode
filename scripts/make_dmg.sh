#!/bin/zsh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; APP="$ROOT/dist/MyNightMode.app"; DMG="$ROOT/dist/MyNightMode.dmg"; [[ -d "$APP" ]] || "$ROOT/scripts/build_app.sh"
rm -f "$DMG"; hdiutil create -volname "MyNightMode" -srcfolder "$APP" -ov -format UDZO "$DMG"; echo "✅ $DMG"; open "$ROOT/dist"
