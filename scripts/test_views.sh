#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUTPUT="${TMPDIR:-/tmp}/mynightmode-view-smoke-checks"
MODULE_CACHE="$ROOT/.build/local-cache/clang"

mkdir -p "$MODULE_CACHE"

xcrun swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx14.0 \
    -module-cache-path "$MODULE_CACHE" \
    "$ROOT/Sources/NoxWindow/App/AppModel.swift" \
    "$ROOT/Sources/NoxWindow/Models/Models.swift" \
    "$ROOT/Sources/NoxWindow/Services/AdaptiveEngine.swift" \
    "$ROOT/Sources/NoxWindow/Services/AppClassifier.swift" \
    "$ROOT/Sources/NoxWindow/Services/DisplayBrightnessReader.swift" \
    "$ROOT/Sources/NoxWindow/Services/HotKeyManager.swift" \
    "$ROOT/Sources/NoxWindow/Services/LoginItemManager.swift" \
    "$ROOT/Sources/NoxWindow/Services/OverlayController.swift" \
    "$ROOT/Sources/NoxWindow/Services/SettingsStore.swift" \
    "$ROOT/Sources/NoxWindow/Views/ContentView.swift" \
    "$ROOT/Sources/NoxWindow/Views/HotKeyRecorderView.swift" \
    "$ROOT/Sources/NoxWindow/Views/MenuBarView.swift" \
    "$ROOT/Sources/NoxWindow/Views/OnboardingView.swift" \
    "$ROOT/Sources/NoxWindow/Views/SettingsView.swift" \
    "$ROOT/Tests/ViewSmokeChecks.swift" \
    -o "$OUTPUT"

"$OUTPUT"
