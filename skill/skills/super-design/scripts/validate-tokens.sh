#!/usr/bin/env bash
# validate-tokens.sh — PostToolUse hook + manual validator.
#
# Blocks edits that introduce hardcoded design values in component code.
#
# Usage:
#   bash validate-tokens.sh <file>            (manual)
#   echo '{"tool_input":{"file_path":"..."}}' | bash validate-tokens.sh   (hook)
#
# Exit codes:
#   0  — pass (possibly with non-blocking warnings)
#   2  — block (hook) / 1 (manual) — violations present

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

# -------- Read input --------
FILE_PATH=""
IS_HOOK=0

if [ -n "${1:-}" ]; then
  FILE_PATH="$1"
else
  IS_HOOK=1
  PAYLOAD=$(cat 2>/dev/null || printf '{}')
  FILE_PATH=$(read_json_field "$PAYLOAD" '.tool_input.file_path')
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0
is_auditable_file "$FILE_PATH" || exit 0
should_skip_file "$FILE_PATH" && exit 0

# -------- Build a comment-stripped version for scanning --------
TMP_CLEAN=$(mktemp)
trap 'rm -f "$TMP_CLEAN"' EXIT
strip_comments "$FILE_PATH" > "$TMP_CLEAN"

VIOLATIONS=()
WARNINGS=()

# -------- 1. Hex literals (block) --------
# Match #rgb and #rrggbb and #rrggbbaa outside comments and strings-that-are-identifiers
HEX_HITS=$(grep -nE '#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b' "$TMP_CLEAN" 2>/dev/null | head -20)
if [ -n "$HEX_HITS" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("HEX: ${line}")
  done <<< "$HEX_HITS"
fi

# -------- 2. rgb/rgba/hsl/hsla literals (block) --------
# Exclude var() fallbacks — rgb(var(--x) / ...) is OK because you're in var territory.
RGB_HITS=$(grep -nE '\b(rgb|rgba|hsl|hsla|lab|lch|oklab|oklch|color)[[:space:]]*\(' "$TMP_CLEAN" 2>/dev/null \
  | grep -v 'var(' \
  | head -20)
if [ -n "$RGB_HITS" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("COLOR_FN: ${line}")
  done <<< "$RGB_HITS"
fi

# -------- 3. Inline style with a color (block) --------
INLINE_COLOR=$(grep -nE 'style=\{\{[^}]*(color|background|border|fill|stroke)[^}]*(#|rgb|hsl)' "$TMP_CLEAN" 2>/dev/null | head -10)
if [ -n "$INLINE_COLOR" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("INLINE_COLOR: ${line}")
  done <<< "$INLINE_COLOR"
fi

# -------- 4. Hardcoded px outside allowed scale (warn if ≤3, block if >3) --------
PX_OFFENDERS=()
while IFS= read -r hit; do
  # Extract Npx values from the line
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    if ! echo "$v" | grep -qE "$ALLOWED_PX_SCALE" && ! echo "$v" | grep -qE "$VIEWPORT_PX_SCALE"; then
      PX_OFFENDERS+=("$v @ $hit")
    fi
  done < <(echo "$hit" | grep -oE '[0-9]+(\.[0-9]+)?px' || true)
done < <(grep -nE '[0-9]+(\.[0-9]+)?px' "$TMP_CLEAN" 2>/dev/null | head -30)

if [ "${#PX_OFFENDERS[@]}" -gt 3 ]; then
  for p in "${PX_OFFENDERS[@]}"; do VIOLATIONS+=("PX_OFF_SCALE: $p"); done
elif [ "${#PX_OFFENDERS[@]}" -gt 0 ]; then
  for p in "${PX_OFFENDERS[@]}"; do WARNINGS+=("PX_OFF_SCALE: $p"); done
fi

# -------- 5. Tailwind arbitrary color or px values (warn) --------
TW_ARBITRARY=$(grep -nE '\[#[0-9a-fA-F]{3,8}\]|\[[0-9]+px\]' "$TMP_CLEAN" 2>/dev/null | head -10)
if [ -n "$TW_ARBITRARY" ]; then
  while IFS= read -r line; do
    WARNINGS+=("TW_ARBITRARY: ${line}")
  done <<< "$TW_ARBITRARY"
fi

# -------- 6. :focus not :focus-visible (warn, CSS files only) --------
case "$FILE_PATH" in
  *.css|*.scss|*.sass)
    # Match :focus NOT followed by -visible.
    FOCUS_BAD=$(grep -nE ':focus([^-]|$)' "$TMP_CLEAN" 2>/dev/null \
      | grep -v ':focus-visible' \
      | grep -v ':focus-within' || true)
    if [ -n "$FOCUS_BAD" ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        WARNINGS+=("FOCUS_NOT_VISIBLE: ${line}")
      done <<< "$FOCUS_BAD"
    fi
    ;;
esac

# -------- 7. outline: none without replacement (warn) --------
# Find rules that set outline:none AND don't set box-shadow or outline: in the same ~3 lines
OUTLINE_NONE=$(grep -nE 'outline[[:space:]]*:[[:space:]]*(none|0)' "$TMP_CLEAN" 2>/dev/null | head -10)
if [ -n "$OUTLINE_NONE" ]; then
  while IFS= read -r hit; do
    lineno=${hit%%:*}
    # Check the next 5 lines for a replacement
    context=$(sed -n "${lineno},$((lineno + 5))p" "$TMP_CLEAN" 2>/dev/null || true)
    if ! echo "$context" | grep -qE '(box-shadow|outline[[:space:]]*:[[:space:]]*[^n0])'; then
      WARNINGS+=("OUTLINE_NONE_NO_REPLACEMENT: ${hit}")
    fi
  done <<< "$OUTLINE_NONE"
fi

# -------- 8. Animating layout properties (warn) --------
BAD_ANIMATION=$(grep -nE 'transition[^;,}]*\b(width|height|top|left|right|bottom|margin|padding)\b' "$TMP_CLEAN" 2>/dev/null | head -10)
if [ -n "$BAD_ANIMATION" ]; then
  while IFS= read -r line; do
    WARNINGS+=("LAYOUT_ANIMATION: ${line}")
  done <<< "$BAD_ANIMATION"
fi

# -------- 9. <img> without alt (block) --------
IMG_NO_ALT=$(grep -nE '<img\b' "$TMP_CLEAN" 2>/dev/null \
  | grep -v 'alt=' \
  | head -10)
if [ -n "$IMG_NO_ALT" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("IMG_NO_ALT: ${line}")
  done <<< "$IMG_NO_ALT"
fi

# -------- 10. Component references primitive tokens directly (warn) --------
# A component should reference semantic tokens (--color-fg, --color-accent)
# not primitive tokens (--color-neutral-900, --color-brand-500).
PRIMITIVE_REF=$(grep -nE '--color-(neutral|gray|slate|brand|indigo|violet|red|green|blue|yellow|amber|orange)-[0-9]+' "$TMP_CLEAN" 2>/dev/null | head -10)
if [ -n "$PRIMITIVE_REF" ]; then
  while IFS= read -r line; do
    WARNINGS+=("PRIMITIVE_TOKEN_REF: ${line}  — prefer semantic token (--color-fg, --color-accent)")
  done <<< "$PRIMITIVE_REF"
fi

# -------- Report --------
V=${#VIOLATIONS[@]}
W=${#WARNINGS[@]}

if [ "$V" -eq 0 ] && [ "$W" -eq 0 ]; then
  [ "$IS_HOOK" -eq 0 ] && ok "$FILE_PATH — token audit passed"
  exit 0
fi

MSG="super-design: token audit for ${FILE_PATH}"$'\n'
if [ "$V" -gt 0 ]; then
  MSG+=$'\n'"❌ $V violation(s) — these block the edit:"$'\n'
  for v in "${VIOLATIONS[@]}"; do
    MSG+="  • $v"$'\n'
  done
fi
if [ "$W" -gt 0 ]; then
  MSG+=$'\n'"⚠ $W warning(s) — please review:"$'\n'
  for w in "${WARNINGS[@]}"; do
    MSG+="  • $w"$'\n'
  done
fi
MSG+=$'\n'"Fix: reference semantic tokens from DESIGN.md. See references/component-quality-gates.md."

if [ "$V" -gt 0 ]; then
  if [ "$IS_HOOK" -eq 1 ]; then
    printf '%s\n' "$MSG" >&2
    exit 2
  else
    printf '%s\n' "$MSG"
    exit 1
  fi
else
  if [ "$IS_HOOK" -eq 1 ]; then
    # Non-blocking context surface via JSON output
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$MSG" | jq -Rs '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: .}}'
    else
      esc=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')
      printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
    fi
  else
    printf '%s\n' "$MSG"
  fi
  exit 0
fi
