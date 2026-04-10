#!/usr/bin/env bash
# validate-component.sh — checks LOC, function length, complexity, depth,
# state coverage, touch targets, and responsive enforcement.
# Runs as PostToolUse hook on Edit|Write|MultiEdit, or manually.
#
# v1.2.0 changes (guardrails hardening):
#   - File LOC thresholds tightened: 300 hard (was 500) / 150 warn (was 300)
#     to match SKILL.md's stated "max 300 LOC/component" claim.
#   - Hook count thresholds tightened: 10 hard (was 12) / 6 warn (was 8).
#   - JSX depth thresholds tightened: 5 hard (was 6) / 3 warn (was 4).
#   - Added per-function LOC tracking (awk brace-counter, not a naive avg).
#   - Touch target check: interactive elements must meet 44×44 CSS px
#     (min-h-11/min-w-11, [44px]/[2.75rem], or CSS min-height/min-width).
#   - NO_RESPONSIVE promoted from WARNING to VIOLATION for layout files.
#   - NO_FLUID_HEADING added: warn on h1/h2/h3 without clamp()/responsive
#     text classes — headings should scale across breakpoints.

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

# Tightened thresholds — matches SKILL.md's "max 300 LOC/component" claim.
if [ "$LOC" -gt 300 ]; then
  VIOLATIONS+=("FILE_TOO_LARGE: $LOC lines (hard limit 300) — split into sub-components. SKILL.md §'The one-paragraph rule' requires <300 LOC/component.")
elif [ "$LOC" -gt 150 ]; then
  WARNINGS+=("FILE_LARGE: $LOC lines (soft limit 150) — consider extracting sub-components before you hit 300")
fi

# -------- Per-function LOC tracking --------
# Awk-based brace counter: walks the file, tracks when we enter a function
# declaration, counts lines until the matching closing brace, reports the
# worst-offender function. Handles both `function name() {}` and
# `const Name = (...) => {}` forms. Depth counter is character-accurate.
#
# Output format: "<max_loc>\t<fn_name>"
FN_PROBE=$(awk '
  BEGIN { in_fn = 0; fn_start = 0; fn_name = ""; depth = 0; max_loc = 0; max_name = "none" }

  # Start a new function when we see a declaration at depth 0
  !in_fn && /^[[:space:]]*(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?(function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*|const[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*(\([^)]*\)|async[[:space:]]*\([^)]*\))[[:space:]]*=>)/ {
    in_fn = 1
    fn_start = NR
    # Extract a best-effort name
    if (match($0, /function[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)/, m1)) {
      fn_name = m1[1]
    } else if (match($0, /const[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)/, m2)) {
      fn_name = m2[1]
    } else {
      fn_name = "anonymous@" NR
    }
    depth = 0
  }

  # Once inside a function body, count braces character-by-character
  in_fn {
    line = $0
    n = length(line)
    for (i = 1; i <= n; i++) {
      c = substr(line, i, 1)
      if (c == "{") depth++
      else if (c == "}") {
        depth--
        if (depth == 0 && NR > fn_start) {
          loc = NR - fn_start + 1
          if (loc > max_loc) { max_loc = loc; max_name = fn_name }
          in_fn = 0
          break
        }
      }
    }
  }

  END { printf "%d\t%s\n", max_loc, max_name }
' "$TMP_CLEAN" 2>/dev/null)

MAX_FN_LOC=$(printf '%s' "$FN_PROBE" | cut -f1)
MAX_FN_NAME=$(printf '%s' "$FN_PROBE" | cut -f2)
MAX_FN_LOC=${MAX_FN_LOC:-0}

if [ "$MAX_FN_LOC" -gt 80 ]; then
  VIOLATIONS+=("FUNCTION_TOO_LARGE: ${MAX_FN_NAME}() is $MAX_FN_LOC LOC (hard limit 80) — split into smaller helpers")
elif [ "$MAX_FN_LOC" -gt 40 ]; then
  WARNINGS+=("FUNCTION_LARGE: ${MAX_FN_NAME}() is $MAX_FN_LOC LOC (soft limit 40) — consider extracting helpers")
fi

# -------- Multi-component count --------
EXPORTS=$(count_matches '^export[[:space:]]+(default[[:space:]]+)?(function|const|class)[[:space:]]+[A-Z]' "$TMP_CLEAN")
if [ "$EXPORTS" -gt 3 ]; then
  WARNINGS+=("MULTI_COMPONENT: $EXPORTS component exports in one file — split into separate files for reusability")
fi

# -------- Hook count --------
HOOK_COUNT=$(count_matches '\buse[A-Z][a-zA-Z]+[[:space:]]*\(' "$TMP_CLEAN")
if [ "$HOOK_COUNT" -gt 10 ]; then
  VIOLATIONS+=("TOO_MANY_HOOKS: $HOOK_COUNT useX() calls (hard limit 10) — extract a custom hook")
elif [ "$HOOK_COUNT" -gt 6 ]; then
  WARNINGS+=("MANY_HOOKS: $HOOK_COUNT useX() calls (soft limit 6) — consider extracting a custom hook")
fi

# -------- JSX depth --------
DEPTH=$(jsx_max_depth "$TMP_CLEAN")
DEPTH=${DEPTH:-0}
if [ "$DEPTH" -gt 6 ]; then
  VIOLATIONS+=("JSX_TOO_DEEP: depth $DEPTH (hard limit 6) — extract nested children into sub-components")
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

# -------- Touch target check (v1.2.0) --------
# WCAG 2.2 SC 2.5.8 requires 24×24 minimum; Apple HIG + Material + WCAG 2.2 AAA
# recommend 44×44. We warn if interactive elements exist and no explicit
# minimum size token is present. Acceptable tokens:
#   - Tailwind: min-h-11, min-w-11, h-11, w-11 (44px), min-h-[44px], min-h-[2.75rem]
#   - CSS: min-height: 44px, min-height: 2.75rem (also 11 = 2.75rem via --spacing)
if [ "$IS_INTERACTIVE" -eq 1 ]; then
  HAS_TOUCH_TARGET=0
  # Tailwind spacing utilities (min-h-11 == 2.75rem == 44px with default 0.25rem base)
  if grep -qE '(^|[[:space:]"'"'"'])(min-h-1[12]|min-w-1[12]|h-1[12]|w-1[12])(\b|[[:space:]"'"'"'])' "$TMP_CLEAN" 2>/dev/null; then
    HAS_TOUCH_TARGET=1
  fi
  # Arbitrary-value escape hatches
  if grep -qE 'min-h-\[(4[4-9]|[5-9][0-9]+)px\]|min-w-\[(4[4-9]|[5-9][0-9]+)px\]|min-h-\[2\.[7-9]|min-w-\[2\.[7-9]' "$TMP_CLEAN" 2>/dev/null; then
    HAS_TOUCH_TARGET=1
  fi
  # Raw CSS
  if grep -qE 'min-height[[:space:]]*:[[:space:]]*(4[4-9]|[5-9][0-9]+)px|min-width[[:space:]]*:[[:space:]]*(4[4-9]|[5-9][0-9]+)px|min-height[[:space:]]*:[[:space:]]*2\.[7-9]|min-width[[:space:]]*:[[:space:]]*2\.[7-9]' "$TMP_CLEAN" 2>/dev/null; then
    HAS_TOUCH_TARGET=1
  fi
  if [ "$HAS_TOUCH_TARGET" -eq 0 ]; then
    WARNINGS+=("TOUCH_TARGET: interactive element with no explicit 44×44 minimum size — fails Apple HIG, risks WCAG 2.2 SC 2.5.8 on mobile. Add min-h-11 min-w-11 (or equivalent).")
  fi
fi

# -------- Forced-colors mode --------
if [ "$IS_INTERACTIVE" -eq 1 ]; then
  if ! grep -qE 'forced-colors' "$TMP_CLEAN" 2>/dev/null; then
    WARNINGS+=("NO_FORCED_COLORS: no forced-colors: adjust or media query — breaks in Windows High Contrast")
  fi
fi

# -------- Responsive breakpoints (v1.2.0: promoted to BLOCK for layouts) --------
# Layout containers MUST have responsive variants. Buttons and small primitives
# are exempt — they inherit responsive behavior from their parents.
IS_LAYOUT=0
if grep -qE '(\bgrid\b|flex-(col|row)|\bcontainer\b|<main\b|<section\b|<article\b|<aside\b|<nav\b|className=.*Layout|Layout[[:space:]]*\()' "$TMP_CLEAN" 2>/dev/null; then
  IS_LAYOUT=1
fi
if [ "$IS_LAYOUT" -eq 1 ]; then
  HAS_RESPONSIVE=0
  # Tailwind breakpoint prefixes
  if grep -qE '(\bsm:|\bmd:|\blg:|\bxl:|\b2xl:|@container|@media)' "$TMP_CLEAN" 2>/dev/null; then
    HAS_RESPONSIVE=1
  fi
  # Intrinsic responsive primitives (auto-fit minmax, clamp, grid-template-columns)
  if grep -qE 'auto-fit|auto-fill|minmax\(|clamp\(|fr[[:space:]]|fr,' "$TMP_CLEAN" 2>/dev/null; then
    HAS_RESPONSIVE=1
  fi
  # Container queries
  if grep -qE '@container|container-type|container-name' "$TMP_CLEAN" 2>/dev/null; then
    HAS_RESPONSIVE=1
  fi
  if [ "$HAS_RESPONSIVE" -eq 0 ]; then
    VIOLATIONS+=("NO_RESPONSIVE: layout component has no breakpoint variants, container queries, or intrinsic responsive primitives (auto-fit/minmax/clamp). Must support 320px→1920px per SKILL.md §'Responsive guardrails'.")
  fi
fi

# -------- Fluid heading check (v1.2.0) --------
# h1/h2/h3 should scale across breakpoints — either via clamp() / fluid tokens
# or via responsive Tailwind text-* prefixes. A hardcoded text-3xl on an h1
# looks huge on mobile and small on ultra-wide.
if grep -qE '<h[1-3][[:space:]>]' "$TMP_CLEAN" 2>/dev/null; then
  HAS_FLUID_HEADING=0
  if grep -qE 'clamp\(|text-\[clamp|--text-|text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|8xl|9xl)[[:space:]"'"'"']*[[:space:]]*(sm:|md:|lg:|xl:|2xl:)' "$TMP_CLEAN" 2>/dev/null; then
    HAS_FLUID_HEADING=1
  fi
  # Also accept when a responsive text- class exists anywhere near a heading
  if grep -qE '(sm:|md:|lg:|xl:|2xl:)text-' "$TMP_CLEAN" 2>/dev/null; then
    HAS_FLUID_HEADING=1
  fi
  if [ "$HAS_FLUID_HEADING" -eq 0 ]; then
    WARNINGS+=("NO_FLUID_HEADING: h1/h2/h3 without clamp() or responsive text-* variants — heading won't scale between mobile and ultra-wide")
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

MSG="component audit: ${FILE_PATH} (LOC=$LOC, fn=$MAX_FN_LOC, hooks=$HOOK_COUNT, depth=$DEPTH)"$'\n'

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
