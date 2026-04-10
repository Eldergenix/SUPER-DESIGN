#!/usr/bin/env bash
# validate-tokens.sh — PostToolUse hook for Edit|Write|MultiEdit.
#
# Reads JSON from stdin (the hook payload from Claude Code),
# extracts tool_input.file_path, and scans it for hardcoded
# design tokens (hex, rgb, hsl, unscaled px, inline colors).
#
# Exit 0 = pass (no blocking), emits stdout JSON with warnings
# Exit 2 = block the edit
#
# Safe to also run manually:  bash validate-tokens.sh path/to/file.tsx

set -eo pipefail

# -------- Read input --------
FILE_PATH=""
IS_STDIN=1

if [ -n "$1" ]; then
  # Manual invocation with a file path argument
  FILE_PATH="$1"
  IS_STDIN=0
else
  # Hook invocation — parse JSON from stdin
  PAYLOAD=$(cat 2>/dev/null || echo '{}')
  FILE_PATH=$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null || echo "")
fi

# -------- Early exits --------

# Nothing to check
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only check component/style files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.ts|*.js|*.vue|*.svelte|*.css|*.scss|*.astro) ;;
  *) exit 0 ;;
esac

# Skip token/theme/config files themselves (they're ALLOWED to contain literals)
case "$FILE_PATH" in
  *tailwind.config.*|*theme.ts|*theme.js|*theme.css|*globals.css|*tokens.json|*tokens.ts|*DESIGN.md|*design-tokens.*|*.claude-plugin/*|*node_modules/*|*/dist/*|*/build/*|*/.next/*)
    exit 0 ;;
esac

# -------- Allowed px scale --------
ALLOWED_PX='^(0|1|2|3|4|6|8|10|12|14|16|20|24|28|32|36|40|44|48|56|64|72|80|96|112|128|160|192|224|256|1920|1440|1280|1024|768|640|375|320)px$'

# -------- Violations collector --------
VIOLATIONS=()
WARNINGS=()

# 1. Hex literals
HEX_MATCHES=$(grep -nE '#([0-9a-fA-F]{3}){1,2}\b' "$FILE_PATH" 2>/dev/null | grep -v -E '(//|/\*|\*|@param|@return|^\s*\*)' || true)
if [ -n "$HEX_MATCHES" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("HEX: $line")
  done <<< "$HEX_MATCHES"
fi

# 2. rgb/rgba/hsl/hsla literals (exclude CSS var fallbacks inside var())
RGB_MATCHES=$(grep -nE '\b(rgb|rgba|hsl|hsla)\s*\(' "$FILE_PATH" 2>/dev/null | grep -v -E 'var\s*\(' || true)
if [ -n "$RGB_MATCHES" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("RGB/HSL: $line")
  done <<< "$RGB_MATCHES"
fi

# 3. Inline style with color
INLINE_STYLE=$(grep -nE 'style=\{\{[^}]*color:\s*["'\''`]#' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$INLINE_STYLE" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("INLINE_COLOR: $line")
  done <<< "$INLINE_STYLE"
fi

# 4. Hardcoded px outside allowed scale (warn)
PX_MATCHES=$(grep -nE '\b[0-9]+(\.[0-9]+)?px\b' "$FILE_PATH" 2>/dev/null | grep -v -E '(//|/\*|\*\s|@param)' || true)
if [ -n "$PX_MATCHES" ]; then
  while IFS= read -r line; do
    # Extract all Npx values on the line
    values=$(echo "$line" | grep -oE '[0-9]+(\.[0-9]+)?px' || true)
    for v in $values; do
      if ! echo "$v" | grep -qE "$ALLOWED_PX"; then
        WARNINGS+=("PX_OFF_SCALE: $line  [value=$v]")
      fi
    done
  done <<< "$PX_MATCHES"
fi

# 5. :focus without :focus-visible (in CSS)
case "$FILE_PATH" in
  *.css|*.scss)
    FOCUS_MATCHES=$(grep -nE ':focus(?!-visible)' "$FILE_PATH" 2>/dev/null || true)
    # Fallback for grep without lookahead
    if [ -z "$FOCUS_MATCHES" ]; then
      FOCUS_MATCHES=$(grep -nE ':focus' "$FILE_PATH" | grep -v ':focus-visible' || true)
    fi
    if [ -n "$FOCUS_MATCHES" ]; then
      while IFS= read -r line; do
        WARNINGS+=("FOCUS_NOT_VISIBLE: $line")
      done <<< "$FOCUS_MATCHES"
    fi
    ;;
esac

# 6. outline: none without replacement in same rule
OUTLINE_NONE=$(grep -nE 'outline\s*:\s*none' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$OUTLINE_NONE" ]; then
  while IFS= read -r line; do
    WARNINGS+=("OUTLINE_NONE: $line")
  done <<< "$OUTLINE_NONE"
fi

# 7. Animating disallowed properties
BAD_TRANSITION=$(grep -nE 'transition[^;]*\b(width|height|top|left|margin|padding)\b' "$FILE_PATH" 2>/dev/null || true)
if [ -n "$BAD_TRANSITION" ]; then
  while IFS= read -r line; do
    WARNINGS+=("LAYOUT_ANIMATION: $line")
  done <<< "$BAD_TRANSITION"
fi

# 8. Missing alt on <img>
IMG_NO_ALT=$(grep -nE '<img(\s+[^>]*)?(?<!alt=)\s*[/>]' "$FILE_PATH" 2>/dev/null || true)
if [ -z "$IMG_NO_ALT" ]; then
  # Fallback without lookbehind
  IMG_NO_ALT=$(grep -nE '<img' "$FILE_PATH" | grep -v 'alt=' || true)
fi
if [ -n "$IMG_NO_ALT" ]; then
  while IFS= read -r line; do
    VIOLATIONS+=("IMG_NO_ALT: $line")
  done <<< "$IMG_NO_ALT"
fi

# -------- Report --------
VIOLATION_COUNT=${#VIOLATIONS[@]}
WARNING_COUNT=${#WARNINGS[@]}

if [ "$VIOLATION_COUNT" -eq 0 ] && [ "$WARNING_COUNT" -eq 0 ]; then
  # Clean pass
  if [ "$IS_STDIN" -eq 1 ]; then
    exit 0
  else
    echo "✓ $FILE_PATH — token audit passed"
    exit 0
  fi
fi

# Build message
MSG="awesome-design-md: token audit for $FILE_PATH"$'\n'
if [ "$VIOLATION_COUNT" -gt 0 ]; then
  MSG+=$'\n'"❌ $VIOLATION_COUNT violation(s) — these block the edit:"$'\n'
  for v in "${VIOLATIONS[@]}"; do
    MSG+="  • $v"$'\n'
  done
fi
if [ "$WARNING_COUNT" -gt 0 ]; then
  MSG+=$'\n'"⚠ $WARNING_COUNT warning(s) — please review:"$'\n'
  for w in "${WARNINGS[@]}"; do
    MSG+="  • $w"$'\n'
  done
fi
MSG+=$'\n'"Fix: replace literal values with tokens from DESIGN.md. See references/component-quality-gates.md."

if [ "$VIOLATION_COUNT" -gt 0 ]; then
  if [ "$IS_STDIN" -eq 1 ]; then
    # Block the edit — exit 2 with stderr message
    printf '%s\n' "$MSG" >&2
    exit 2
  else
    printf '%s\n' "$MSG"
    exit 1
  fi
else
  # Warnings only — pass but surface
  if [ "$IS_STDIN" -eq 1 ]; then
    # Use JSON output to attach non-blocking context
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}' \
      "$(printf '%s' "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
  else
    printf '%s\n' "$MSG"
  fi
  exit 0
fi
