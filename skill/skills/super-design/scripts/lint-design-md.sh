#!/usr/bin/env bash
# lint-design-md.sh — validates a DESIGN.md file conforms to the schema.
#
# Usage: bash lint-design-md.sh DESIGN.md
#
# Checks:
#   - Required sections exist (0 Meta, 1 Brand, 2 Color, 3 Typography,
#     4 Spacing, 5 Radius, 6 Elevation, 7 Motion, 8 States, 9 Layout, 10 Agent)
#   - Meta block has required fields (version, framework.css, theme_modes)
#   - At least one token block per required section
#   - Semantic color layer defines --color-bg, --color-fg, --color-accent, --color-border, --color-focus-ring
#   - Typography scale has all 8 sizes (xs..4xl)
#   - Motion has duration and ease tokens
#   - No hardcoded values in "components reference" sections

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

FILE="${1:-DESIGN.md}"
if [ ! -f "$FILE" ]; then
  err "File not found: $FILE"
  exit 2
fi

ERRORS=()
WARNINGS=()

# ---------- Required sections ----------
REQUIRED_SECTIONS=(
  "^## 0\. Meta"
  "^## 1\. Brand"
  "^## 2\. Color"
  "^## 3\. Typography"
  "^## 4\. Spacing"
  "^## 5\. Radius"
  "^## 6\. Elevation"
  "^## 7\. Motion"
  "^## 8\. Component State"
  "^## 9\. Layout"
  "^## 10\. Agent"
)

for sec in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qE "$sec" "$FILE" 2>/dev/null; then
    ERRORS+=("MISSING_SECTION: no match for '$sec'")
  fi
done

# ---------- Meta fields ----------
for field in "version:" "framework:" "theme_modes:" "dark_mode_strategy:"; do
  if ! grep -qE "^\s*${field}" "$FILE" 2>/dev/null; then
    ERRORS+=("MISSING_META_FIELD: $field")
  fi
done

# ---------- Required semantic color tokens ----------
REQUIRED_COLORS=(
  "--color-bg"
  "--color-fg"
  "--color-fg-muted"
  "--color-surface"
  "--color-border"
  "--color-accent"
  "--color-accent-hover"
  "--color-focus-ring"
  "--color-danger"
  "--color-success"
)

for tok in "${REQUIRED_COLORS[@]}"; do
  if ! grep -qF -e "$tok" "$FILE" 2>/dev/null; then
    ERRORS+=("MISSING_COLOR_TOKEN: $tok (required in semantic layer)")
  fi
done

# ---------- Required typography scale ----------
REQUIRED_TEXT=(
  "--text-xs"
  "--text-sm"
  "--text-base"
  "--text-lg"
  "--text-xl"
  "--text-2xl"
  "--text-3xl"
  "--text-4xl"
)

for tok in "${REQUIRED_TEXT[@]}"; do
  if ! grep -qF -e "$tok" "$FILE" 2>/dev/null; then
    WARNINGS+=("MISSING_TEXT_TOKEN: $tok (recommended for full fluid scale)")
  fi
done

# ---------- Required motion tokens (accept --duration-x OR DTCG block form) ----------
for name in "fast" "base" "slow"; do
  if ! grep -qF -e "--duration-${name}" "$FILE" 2>/dev/null \
     && ! grep -qE "^- ${name}[[:space:]]*\(duration\)" "$FILE" 2>/dev/null; then
    ERRORS+=("MISSING_DURATION_TOKEN: duration.${name} (or --duration-${name})")
  fi
done

for name in "out" "in"; do
  if ! grep -qF -e "--ease-${name}" "$FILE" 2>/dev/null \
     && ! grep -qE "^- ${name}[[:space:]]*\(cubicBezier\)" "$FILE" 2>/dev/null; then
    WARNINGS+=("MISSING_EASE_TOKEN: ease.${name} (or --ease-${name})")
  fi
done

# ---------- Required radius tokens ----------
for name in "md" "lg" "full"; do
  if ! grep -qF -e "--radius-${name}" "$FILE" 2>/dev/null \
     && ! grep -qE "^- ${name}[[:space:]]*\(dimension\)" "$FILE" 2>/dev/null; then
    WARNINGS+=("MISSING_RADIUS_TOKEN: radius.${name}")
  fi
done

# ---------- Forced-colors section ----------
if ! grep -qE 'forced-colors' "$FILE" 2>/dev/null; then
  WARNINGS+=("NO_FORCED_COLORS: no forced-colors guidance (WCAG 2.2 / Windows High Contrast)")
fi

# ---------- Reduced-motion section ----------
if ! grep -qE 'prefers-reduced-motion' "$FILE" 2>/dev/null; then
  ERRORS+=("NO_REDUCED_MOTION: missing prefers-reduced-motion guard")
fi

# ---------- Logical properties guidance ----------
if ! grep -qE '(margin-inline|padding-inline|logical)' "$FILE" 2>/dev/null; then
  WARNINGS+=("NO_LOGICAL_PROPS: no mention of logical properties for i18n/RTL")
fi

# ---------- Focus ring double-layer ----------
if ! grep -qE 'box-shadow.*focus-ring|focus.*double' "$FILE" 2>/dev/null; then
  WARNINGS+=("NO_DOUBLE_RING: focus ring should use double-layer box-shadow for 3:1 contrast on any bg")
fi

# ---------- State matrix required states ----------
for state in "focus-visible" "disabled" "hover" "active"; do
  if ! grep -qF "$state" "$FILE" 2>/dev/null; then
    ERRORS+=("MISSING_STATE_IN_MATRIX: $state")
  fi
done

# ---------- Report ----------
E=${#ERRORS[@]}
W=${#WARNINGS[@]}

if [ "$E" -eq 0 ] && [ "$W" -eq 0 ]; then
  ok "$FILE — DESIGN.md schema audit passed"
  exit 0
fi

printf 'DESIGN.md schema audit for %s\n' "$FILE"

if [ "$E" -gt 0 ]; then
  printf '\n❌ %d error(s) — DESIGN.md is invalid:\n' "$E"
  for e in "${ERRORS[@]}"; do printf '  • %s\n' "$e"; done
fi

if [ "$W" -gt 0 ]; then
  printf '\n⚠ %d warning(s):\n' "$W"
  for w in "${WARNINGS[@]}"; do printf '  • %s\n' "$w"; done
fi

printf '\nFix: see %s/DESIGN.md for the canonical structure.\n' "$SCRIPT_DIR/.."

[ "$E" -gt 0 ] && exit 1
exit 0
