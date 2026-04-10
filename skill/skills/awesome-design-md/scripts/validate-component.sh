#!/usr/bin/env bash
# validate-component.sh — checks LOC, complexity, depth, state coverage.
# Runs as PostToolUse hook on Edit|Write|MultiEdit, or manually.

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

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

# Only check JSX/Vue/Svelte component files — skip CSS
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte|*.astro) ;;
  *) exit 0 ;;
esac

should_skip_file "$FILE_PATH" && exit 0

WARNINGS=()
VIOLATIONS=()

TMP_CLEAN=$(mktemp)
trap 'rm -f "$TMP_CLEAN"' EXIT
strip_comments "$FILE_PATH" > "$TMP_CLEAN"

# -------- LOC count (non-blank, non-comment) --------
LOC=$(awk 'NF' "$TMP_CLEAN" 2>/dev/null | wc -l | tr -d '[:space:]')
LOC=${LOC:-0}

if [ "$LOC" -gt 500 ]; then
  VIOLATIONS+=("FILE_TOO_LARGE: $LOC lines (hard limit 500) — split into sub-components")
elif [ "$LOC" -gt 300 ]; then
  WARNINGS+=("FILE_LARGE: $LOC lines (soft limit 300) — consider extracting")
fi

# -------- Multi-component count --------
EXPORTS=$(count_matches '^export[[:space:]]+(default[[:space:]]+)?(function|const|class)[[:space:]]+[A-Z]' "$TMP_CLEAN")
if [ "$EXPORTS" -gt 3 ]; then
  WARNINGS+=("MULTI_COMPONENT: $EXPORTS component exports in one file — split into separate files")
fi

# -------- Hook count --------
HOOK_COUNT=$(count_matches '\buse[A-Z][a-zA-Z]+[[:space:]]*\(' "$TMP_CLEAN")
if [ "$HOOK_COUNT" -gt 12 ]; then
  VIOLATIONS+=("TOO_MANY_HOOKS: $HOOK_COUNT useX() calls (hard limit 12) — extract a custom hook")
elif [ "$HOOK_COUNT" -gt 8 ]; then
  WARNINGS+=("MANY_HOOKS: $HOOK_COUNT useX() calls — consider extracting a custom hook")
fi

# -------- JSX depth (actual open-tag counting, not whitespace) --------
DEPTH=$(jsx_max_depth "$TMP_CLEAN")
DEPTH=${DEPTH:-0}
if [ "$DEPTH" -gt 6 ]; then
  VIOLATIONS+=("JSX_TOO_DEEP: depth $DEPTH (hard limit 6) — extract nested children")
elif [ "$DEPTH" -gt 4 ]; then
  WARNINGS+=("JSX_DEEP: depth $DEPTH (soft limit 4) — consider extracting")
fi

# -------- State coverage for interactive components --------
IS_INTERACTIVE=0
if grep -qE '(onClick|onChange|onSubmit|role="button"|<button|<input|<select|<a[[:space:]]|href=)' "$TMP_CLEAN" 2>/dev/null; then
  IS_INTERACTIVE=1
fi

if [ "$IS_INTERACTIVE" -eq 1 ]; then
  HAS_HOVER=$(count_matches '(hover:|:hover)' "$TMP_CLEAN")
  HAS_FOCUS=$(count_matches '(focus-visible:|:focus-visible|focus-visible\b)' "$TMP_CLEAN")
  HAS_DISABLED=$(count_matches '(disabled:|:disabled|aria-disabled|\bdisabled=)' "$TMP_CLEAN")
  HAS_ACTIVE=$(count_matches '(active:|:active)' "$TMP_CLEAN")

  [ "$HAS_HOVER"    -eq 0 ] && WARNINGS+=("MISSING_HOVER: interactive element with no hover state")
  [ "$HAS_FOCUS"    -eq 0 ] && VIOLATIONS+=("MISSING_FOCUS_VISIBLE: interactive element with no :focus-visible (WCAG 2.2 AA blocker)")
  [ "$HAS_DISABLED" -eq 0 ] && WARNINGS+=("MISSING_DISABLED: interactive element with no disabled handling")
  [ "$HAS_ACTIVE"   -eq 0 ] && WARNINGS+=("MISSING_ACTIVE: interactive element with no :active feedback")
fi

# -------- Forced-colors mode (warn if interactive and no fallback) --------
if [ "$IS_INTERACTIVE" -eq 1 ]; then
  if ! grep -qE 'forced-colors' "$TMP_CLEAN" 2>/dev/null; then
    WARNINGS+=("NO_FORCED_COLORS: no forced-colors: adjust or media query — breaks in Windows High Contrast")
  fi
fi

# -------- Responsive breakpoints (warn if layout file with none) --------
if grep -qE '(grid|flex-(col|row)|container|Layout|<main|<section)' "$TMP_CLEAN" 2>/dev/null; then
  if ! grep -qE '(sm:|md:|lg:|xl:|2xl:|@container|@media)' "$TMP_CLEAN" 2>/dev/null; then
    WARNINGS+=("NO_RESPONSIVE: layout component has no breakpoint variants")
  fi
fi

# -------- :focus without :focus-visible --------
FOCUS_NOT_VISIBLE=$(grep -cE ':focus([^-]|$)' "$TMP_CLEAN" 2>/dev/null || true)
FOCUS_VISIBLE=$(grep -cE ':focus-visible' "$TMP_CLEAN" 2>/dev/null || true)
FOCUS_NOT_VISIBLE=${FOCUS_NOT_VISIBLE:-0}
FOCUS_VISIBLE=${FOCUS_VISIBLE:-0}
if [ "$FOCUS_NOT_VISIBLE" -gt "$FOCUS_VISIBLE" ]; then
  WARNINGS+=("USES_FOCUS_NOT_VISIBLE: prefer :focus-visible for keyboard-only rings")
fi

# -------- aria-busy on async handler (warn) --------
if grep -qE 'async.*onClick|onClick.*async' "$TMP_CLEAN" 2>/dev/null; then
  if ! grep -qE 'aria-busy' "$TMP_CLEAN" 2>/dev/null; then
    WARNINGS+=("MISSING_ARIA_BUSY: async onClick without aria-busy affordance")
  fi
fi

# -------- Report --------
V=${#VIOLATIONS[@]}
W=${#WARNINGS[@]}

MSG="component audit: ${FILE_PATH} (LOC=$LOC, hooks=$HOOK_COUNT, depth=$DEPTH)"$'\n'

if [ "$V" -gt 0 ]; then
  MSG+=$'\n'"❌ $V violation(s):"$'\n'
  for v in "${VIOLATIONS[@]}"; do MSG+="  • $v"$'\n'; done
fi
if [ "$W" -gt 0 ]; then
  MSG+=$'\n'"⚠ $W warning(s):"$'\n'
  for w in "${WARNINGS[@]}"; do MSG+="  • $w"$'\n'; done
fi

if [ "$V" -eq 0 ] && [ "$W" -eq 0 ]; then
  [ "$IS_HOOK" -eq 0 ] && ok "$FILE_PATH — component audit passed"
  exit 0
fi

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
