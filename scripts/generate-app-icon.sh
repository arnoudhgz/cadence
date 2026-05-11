#!/usr/bin/env bash
# Regenerate Cadence's AppIcon.appiconset from a single 1024x1024 source PNG.
#
# Usage:   scripts/generate-app-icon.sh [path-to-source.png]
# Default source: ./icon-source.png at the repo root.
#
# Output: 10 PNG files inside Cadence/Resources/Assets.xcassets/AppIcon.appiconset/
# Re-run after any change to icon-source.png.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="${1:-$REPO_ROOT/icon-source.png}"
DEST="$REPO_ROOT/Cadence/Resources/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE" ]]; then
    echo "error: source icon not found at $SOURCE" >&2
    exit 1
fi

# Verify source is 1024x1024 — sips will silently resize otherwise.
DIMS=$(sips -g pixelWidth -g pixelHeight "$SOURCE" 2>/dev/null | awk '/pixel(Width|Height)/ {print $2}' | paste -sd 'x' -)
if [[ "$DIMS" != "1024x1024" ]]; then
    echo "warning: source is $DIMS (expected 1024x1024); resizing will still happen" >&2
fi

mkdir -p "$DEST"

# pairs of (output-filename, target-pixel-size)
declare -a SIZES=(
    "icon_16x16.png:16"
    "icon_16x16@2x.png:32"
    "icon_32x32.png:32"
    "icon_32x32@2x.png:64"
    "icon_128x128.png:128"
    "icon_128x128@2x.png:256"
    "icon_256x256.png:256"
    "icon_256x256@2x.png:512"
    "icon_512x512.png:512"
    "icon_512x512@2x.png:1024"
)

for entry in "${SIZES[@]}"; do
    NAME="${entry%%:*}"
    SIZE="${entry##*:}"
    OUT="$DEST/$NAME"
    sips -z "$SIZE" "$SIZE" "$SOURCE" --out "$OUT" >/dev/null
    echo "  $NAME (${SIZE}x${SIZE})"
done

echo
echo "Done. Rebuild Cadence to see the new icon."
