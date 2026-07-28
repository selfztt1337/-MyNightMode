#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUTPUT="${TMPDIR:-/tmp}/nightmode-behavior-checks"
MODULE_CACHE="$ROOT/.build/local-cache/clang"

mkdir -p "$MODULE_CACHE"

xcrun swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx14.0 \
    -module-cache-path "$MODULE_CACHE" \
    "$ROOT/Sources/NoxWindow/Models/Models.swift" \
    "$ROOT/Sources/NoxWindow/Services/AdaptiveEngine.swift" \
    "$ROOT/Sources/NoxWindow/Services/AppClassifier.swift" \
    "$ROOT/Sources/NoxWindow/Services/SettingsStore.swift" \
    "$ROOT/Tests/BehaviorChecks.swift" \
    -o "$OUTPUT"

"$OUTPUT"
