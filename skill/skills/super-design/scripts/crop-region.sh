#!/usr/bin/env bash
# crop-region.sh — crop a rectangular region from a PNG for focused
# vision-model inspection. Crops produce substantially better extraction
# accuracy than one-shot full-frame analysis.
#
# Usage:
#   bash crop-region.sh input.png <x> <y> <w> <h> out.png
#
# Requires: ImageMagick `convert` or `magick`. Falls back to Node + sharp.

set -eo pipefail

INPUT="${1:-}"
X="${2:-}"
Y="${3:-}"
W="${4:-}"
H="${5:-}"
OUTPUT="${6:-}"

if [ -z "$INPUT" ] || [ -z "$X" ] || [ -z "$Y" ] || [ -z "$W" ] || [ -z "$H" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: crop-region.sh input.png <x> <y> <w> <h> out.png" >&2
  exit 2
fi

[ -f "$INPUT" ] || { echo "Input not found: $INPUT" >&2; exit 2; }

mkdir -p "$(dirname "$OUTPUT")"

if command -v magick >/dev/null 2>&1; then
  magick "$INPUT" -crop "${W}x${H}+${X}+${Y}" "$OUTPUT"
elif command -v convert >/dev/null 2>&1; then
  convert "$INPUT" -crop "${W}x${H}+${X}+${Y}" "$OUTPUT"
elif command -v node >/dev/null 2>&1; then
  node -e "
    (async () => {
      let sharp;
      try { sharp = (await import('sharp')).default; }
      catch { console.error('Install ImageMagick OR \"npm i sharp\"'); process.exit(1); }
      await sharp('$INPUT').extract({ left: $X, top: $Y, width: $W, height: $H }).toFile('$OUTPUT');
    })();
  "
else
  echo "Need ImageMagick (magick/convert) or Node.js with sharp" >&2
  exit 1
fi

echo "{\"input\":\"$INPUT\",\"output\":\"$OUTPUT\",\"region\":{\"x\":$X,\"y\":$Y,\"w\":$W,\"h\":$H}}"
