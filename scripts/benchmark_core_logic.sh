#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUTPUT="${TMPDIR:-/tmp}/mynightmode-performance-checks"
MODULE_CACHE="$ROOT/.build/local-cache/clang"

mkdir -p "$MODULE_CACHE"

xcrun swiftc \
    -O \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx14.0 \
    -module-cache-path "$MODULE_CACHE" \
    "$ROOT/Sources/NoxWindow/Models/Models.swift" \
    "$ROOT/Sources/NoxWindow/Services/AdaptiveEngine.swift" \
    "$ROOT/Tests/PerformanceChecks.swift" \
    -o "$OUTPUT"

echo "=== Baseline: every tick submits a render ==="
"$OUTPUT"
echo
echo "=== Refactored: stable appearances are deduplicated ==="
"$OUTPUT" --deduplicate
