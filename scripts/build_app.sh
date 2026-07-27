#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
APP_NAME="MyNightMode"; BINARY_NAME="MyNightMode"; DIST="$ROOT/dist"; APP="$DIST/$APP_NAME.app"; CONTENTS="$APP/Contents"
echo "MyNightMode — verified local build"; echo "=================================="
for tool in swift codesign plutil xcrun; do command -v "$tool" >/dev/null || { echo "Не найден $tool. Выполни: xcode-select --install"; exit 1; }; done
plutil -lint "$ROOT/Info.plist"
echo "[1/6] Swift build"; swift build -c release --product "$BINARY_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"; BINARY="$BIN_DIR/$BINARY_NAME"; [[ -x "$BINARY" ]] || { echo "Нет binary: $BINARY"; exit 1; }
echo "[2/6] App bundle"; rm -rf "$APP"; mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"; install -m 755 "$BINARY" "$CONTENTS/MacOS/$BINARY_NAME"; install -m 644 "$ROOT/Info.plist" "$CONTENTS/Info.plist"
echo "[3/6] Resources"; if [[ -d "$BIN_DIR/MyNightMode_MyNightMode.bundle" ]]; then cp -R "$BIN_DIR/MyNightMode_MyNightMode.bundle" "$CONTENTS/Resources/"; fi
ICONSET="$DIST/AppIcon.iconset"; rm -rf "$ICONSET"; mkdir -p "$ICONSET"; SRC="$ROOT/Resources/AppIcon1024.png"
while IFS=' ' read -r width height filename; do
  [[ -n "$width" && -n "$height" && -n "$filename" ]] || continue
  sips -z "$height" "$width" "$SRC" --out "$ICONSET/$filename" >/dev/null
done <<'ICON_SIZES'
16 16 icon_16x16.png
32 32 icon_16x16@2x.png
32 32 icon_32x32.png
64 64 icon_32x32@2x.png
128 128 icon_128x128.png
256 256 icon_128x128@2x.png
256 256 icon_256x256.png
512 512 icon_256x256@2x.png
512 512 icon_512x512.png
ICON_SIZES
cp "$SRC" "$ICONSET/icon_512x512@2x.png"; iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"; rm -rf "$ICONSET"
echo "[4/6] Sign"; codesign --force --deep --sign - --timestamp=none --entitlements "$ROOT/NoxWindow.entitlements" "$APP"; xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
echo "[5/6] Verify"; codesign --verify --deep --strict --verbose=2 "$APP"; [[ -x "$CONTENTS/MacOS/$BINARY_NAME" ]]
echo "[6/6] Smoke launch"; open "$APP"; sleep 3; pgrep -x "$BINARY_NAME" >/dev/null || { echo "Приложение не запустилось. Запусти scripts/diagnose.sh"; exit 1; }
echo "✅ Готово и запущено: $APP"; open "$DIST"
