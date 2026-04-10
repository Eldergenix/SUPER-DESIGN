#!/usr/bin/env bash
# validate-component.sh — checks LOC, complexity, state coverage.
# Runs as PostToolUse hook on Edit|Write|MultiEdit or manually.

set -eo pipefail

FILE_PATH=""
IS_STDIN=1

if [ -n "$1" ]; then
  FILE_PATH="$1"; IS_STDIN=0
else
  PAYLOAD=$(cat 2>/dev/null || echo '{}')
  FILE_PATH=$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null || echo "")
fi

[ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

case "$FILE_PATH" in
  *node_modules/*|*/dist/*|*/build/*|*/.next/*) exit 0 ;;
esac

WARNINGS=()
VIOLATIONS=()

# Helper: grep count that always returns a single integer
count() {
  local c
  c=$(grep -cE "$1" "$2" 2>/dev/null || true)
  echo "${c:-0}" | head -1
}

# -------- LOC count --------
LOC=$(awk '!/^[[:space:]]*$/' "$FILE_PATH" 2>/dev/null | wc -l | tr -d ' ')
LOC=${LOC:-0}
if [ "$LOC" -gt 500 ]; then
  VIOLATIONS+=("FILE_TOO_LARGE: $LOC lines (hard limit 500)")
elif [ "$LOC" -gt 300 ]; then
  WARNINGS+=("FILE_LARGE: $LOC lines (soft limit 300) — consider extracting sub-components")
fi

# -------- Multi-component count --------
EXPORTS=$(count '^export[[:space:]]+(default[[:space:]]+)?(function|const)[[:space:]]+[A-Z]' "$FILE_PATH")
if [ "$EXPORTS" -gt 3 ]; then
  WARNINGS+=("MULTI_COMPONENT: $EXPORTS component-like exports in one file — split into separate files")
fi

# -------- Hook count --------
HOOK_COUNT=$(count '\buse[A-Z][a-zA-Z]*[[:space:]]*\(' "$FILE_PATH")
if [ "$HOOK_COUNT" -gt 12 ]; then
  VIOLATIONS+=("TOO_MANY_HOOKS: $HOOK_COUNT useX() calls (hard limit 12)")
elif [ "$HOOK_COUNT" -gt 8 ]; then
  WARNINGS+=("MANY_HOOKS: $HOOK_COUNT useX() calls — consider extracting a custom hook")
fi

# -------- JSX depth (rough) --------
MAX_DEPTH=$(grep -oE '^[[:space:]]+<' "$FILE_PATH" 2>/dev/null | awk '{ print length($0)-1 }' | sort -rn | head -1 || true)
MAX_DEPTH=${MAX_DEPTH:-0}
DEPTH_LEVELS=$((MAX_DEPTH / 2))  # assume 2-space indent
if [ "$DEPTH_LEVELS" -gt 6 ]; then
  VIOLATIONS+=("JSX_TOO_DEEP: ~$DEPTH_LEVELS levels nested (hard limit 6)")
elif [ "$DEPTH_LEVELS" -gt 4 ]; then
  WARNINGS+=("JSX_DEEP: ~$DEPTH_LEVELS levels — consider extracting")
fi

# -------- State coverage for interactive components --------
# If file contains onClick / role=button / <button / href — check for hover/focus/disabled
if grep -qE '(onClick|role="button"|<button|href=)' "$FILE_PATH" 2>/dev/null; then
  HAS_HOVER=$(count 'hover:' "$FILE_PATH")
  HAS_FOCUS=$(count 'focus-visible:|focus-visible[[:space:]]|\.focus-visible' "$FILE_PATH")
  HAS_DISABLED=$(count 'disabled:|disabled\b|aria-disabled' "$FILE_PATH")

  [ "$HAS_HOVER" -eq 0 ]    && WARNINGS+=("MISSING_HOVER_STATE: no hover: classes / :hover rules")
  [ "$HAS_FOCUS" -eq 0 ]    && WARNINGS+=("MISSING_FOCUS_VISIBLE: no focus-visible: / :focus-visible")
  [ "$HAS_DISABLED" -eq 0 ] && WARNINGS+=("MISSING_DISABLED_STATE: no disabled handling")
fi

# -------- Responsive breakpoints (warn if no breakpoints in layout files) --------
if grep -qE '(grid|flex|container|Layout)' "$FILE_PATH" 2>/dev/null; then
  if ! grep -qE '(sm:|md:|lg:|xl:|@container|@media)' "$FILE_PATH" 2>/dev/null; then
    WARNINGS+=("NO_RESPONSIVE: layout component has no breakpoint variants or media queries")
  fi
fi

# -------- :focus (not :focus-visible) --------
FOCUS_NOT_VISIBLE=$(count ':focus\b' "$FILE_PATH")
FOCUS_VISIBLE=$(count ':focus-visible' "$FILE_PATH")
if [ "$FOCUS_NOT_VISIBLE" -gt "$FOCUS_VISIBLE" ]; then
  WARNINGS+=("USES_FOCUS_NOT_VISIBLE: prefer :focus-visible for keyboard-only focus rings")
fi

# -------- Report --------
V=${#VIOLATIONS[@]}
W=${#WARNINGS[@]}

MSG="component audit: $FILE_PATH (LOC=$LOC, hooks=$HOOK_COUNT, depth~$DEPTH_LEVELS)"$'\n'

if [ "$V" -gt 0 ]; then
  MSG+=$'\n'"❌ $V violation(s):"$'\n'
  for v in "${VIOLATIONS[@]}"; do MSG+="  • $v"$'\n'; done
fi
if [ "$W" -gt 0 ]; then
  MSG+=$'\n'"⚠ $W warning(s):"$'\n'
  for w in "${WARNINGS[@]}"; do MSG+="  • $w"$'\n'; done
fi

if [ "$V" -eq 0 ] && [ "$W" -eq 0 ]; then
  [ "$IS_STDIN" -eq 0 ] && echo "✓ $FILE_PATH — component audit passed"
  exit 0
fi

if [ "$V" -gt 0 ]; then
  if [ "$IS_STDIN" -eq 1 ]; then
    printf '%s\n' "$MSG" >&2
    exit 2
  else
    printf '%s\n' "$MSG"; exit 1
  fi
else
  if [ "$IS_STDIN" -eq 1 ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}' \
      "$(printf '%s' "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
  else
    printf '%s\n' "$MSG"
  fi
  exit 0
fi
