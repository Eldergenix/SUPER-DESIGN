#!/usr/bin/env bash
# quality-score.sh — 0-100 composite score for a component file.
# Usage: bash quality-score.sh path/to/Component.tsx
#
# Emits JSON to stdout. Exit 0 if score >= 60 (passable), else 1.
# Counts TOTAL matches (grep -o | wc -l), not matching lines.

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

FILE_PATH="${1:-}"
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  printf '{"error":"file not found","file":"%s"}\n' "$FILE_PATH" >&2
  exit 2
fi

TMP_CLEAN=$(mktemp)
trap 'rm -f "$TMP_CLEAN"' EXIT
strip_comments "$FILE_PATH" > "$TMP_CLEAN"

# ---------- LOC (20 pts) ----------
LOC=$(awk 'NF' "$TMP_CLEAN" 2>/dev/null | wc -l | tr -d '[:space:]')
LOC=${LOC:-0}
if   [ "$LOC" -le 200 ]; then LOC_SCORE=20
elif [ "$LOC" -le 300 ]; then LOC_SCORE=15
elif [ "$LOC" -le 500 ]; then LOC_SCORE=8
else LOC_SCORE=0
fi

# ---------- Complexity (20 pts) ----------
CYCLO=$(count_matches '\b(if|else[[:space:]]+if|for|while|case|catch|\?\?|\&\&|\|\|)\b' "$TMP_CLEAN")
DEPTH=$(jsx_max_depth "$TMP_CLEAN")
DEPTH=${DEPTH:-0}
HOOK_COUNT=$(count_matches '\buse[A-Z][a-zA-Z]+[[:space:]]*\(' "$TMP_CLEAN")

if   [ "$CYCLO" -le 10 ] && [ "$DEPTH" -le 4 ] && [ "$HOOK_COUNT" -le 8 ]; then COMPLEX_SCORE=20
elif [ "$CYCLO" -le 15 ] && [ "$DEPTH" -le 6 ] && [ "$HOOK_COUNT" -le 12 ]; then COMPLEX_SCORE=10
else COMPLEX_SCORE=0
fi

# ---------- Token usage (20 pts) — total matches, not line counts ----------
HEX=$(count_matches '#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b' "$TMP_CLEAN")
RGB=$(count_matches '\b(rgb|rgba|hsl|hsla|oklch|oklab|lab|lch)[[:space:]]*\(' "$TMP_CLEAN")
# Subtract var()-wrapped color function calls (those are OK)
VAR_COLOR=$(count_matches '(rgb|rgba|hsl|hsla|oklch|oklab)[[:space:]]*\([[:space:]]*var\(' "$TMP_CLEAN")
RGB=$((RGB - VAR_COLOR))
[ "$RGB" -lt 0 ] && RGB=0

BAD_PX=0
while IFS= read -r v; do
  [ -z "$v" ] && continue
  if ! echo "$v" | grep -qE "$ALLOWED_PX_SCALE" && ! echo "$v" | grep -qE "$VIEWPORT_PX_SCALE"; then
    BAD_PX=$((BAD_PX + 1))
  fi
done < <(grep -oE '[0-9]+(\.[0-9]+)?px' "$TMP_CLEAN" 2>/dev/null || true)

PRIMITIVE_REF=$(count_matches '--color-(neutral|gray|slate|brand|indigo|violet|red|green|blue|yellow)-[0-9]+' "$TMP_CLEAN")

TOTAL_LITERALS=$((HEX + RGB + BAD_PX))
if   [ "$TOTAL_LITERALS" -eq 0 ] && [ "$PRIMITIVE_REF" -eq 0 ]; then TOKEN_SCORE=20
elif [ "$TOTAL_LITERALS" -eq 0 ] && [ "$PRIMITIVE_REF" -le 2 ]; then TOKEN_SCORE=15
elif [ "$TOTAL_LITERALS" -le 2 ]; then TOKEN_SCORE=8
else TOKEN_SCORE=0
fi

# ---------- A11y (15 pts) ----------
A11Y_ISSUES=0

# img without alt
IMG_TOTAL=$(count_matches '<img\b' "$TMP_CLEAN")
IMG_WITH_ALT=$(grep -nE '<img\b' "$TMP_CLEAN" 2>/dev/null | grep -c 'alt=' || true)
IMG_WITH_ALT=${IMG_WITH_ALT:-0}
if [ "$IMG_TOTAL" -gt "$IMG_WITH_ALT" ]; then
  A11Y_ISSUES=$((A11Y_ISSUES + 1))
fi

# onClick without keyboard handler on non-button elements
HAS_ON_CLICK_DIV=$(count_matches '<(div|span|li|td|tr)[^>]*\bonClick' "$TMP_CLEAN")
HAS_ON_KEY=$(count_matches 'onKey(Down|Up|Press)' "$TMP_CLEAN")
if [ "$HAS_ON_CLICK_DIV" -gt 0 ] && [ "$HAS_ON_KEY" -eq 0 ]; then
  A11Y_ISSUES=$((A11Y_ISSUES + 1))
fi

# :focus without :focus-visible
HAS_FOCUS=$(count_matches ':focus([^-]|$)' "$TMP_CLEAN")
HAS_FOCUS_VISIBLE=$(count_matches ':focus-visible' "$TMP_CLEAN")
if [ "$HAS_FOCUS" -gt "$HAS_FOCUS_VISIBLE" ]; then
  A11Y_ISSUES=$((A11Y_ISSUES + 1))
fi

# outline:none without replacement
if grep -qE 'outline[[:space:]]*:[[:space:]]*(none|0)' "$TMP_CLEAN" 2>/dev/null; then
  if ! grep -qE '(box-shadow|shadow-.*ring|ring-)' "$TMP_CLEAN" 2>/dev/null; then
    A11Y_ISSUES=$((A11Y_ISSUES + 1))
  fi
fi

# Interactive element missing aria/label entirely
if grep -qE '(onClick|onChange|onSubmit)' "$TMP_CLEAN" 2>/dev/null; then
  if ! grep -qE '(aria-|alt=|<label|<button|<a[[:space:]]|role=)' "$TMP_CLEAN" 2>/dev/null; then
    A11Y_ISSUES=$((A11Y_ISSUES + 1))
  fi
fi

if   [ "$A11Y_ISSUES" -eq 0 ]; then A11Y_SCORE=15
elif [ "$A11Y_ISSUES" -le 2 ]; then A11Y_SCORE=8
else A11Y_SCORE=0
fi

# ---------- Responsive (10 pts) ----------
RESP=$(count_matches '(sm:|md:|lg:|xl:|2xl:|@container|@media|clamp\()' "$TMP_CLEAN")
if   [ "$RESP" -ge 3 ]; then RESP_SCORE=10
elif [ "$RESP" -ge 1 ]; then RESP_SCORE=5
else RESP_SCORE=0
fi

# ---------- States (10 pts) ----------
STATE_COUNT=0
grep -qE '(hover:|:hover)' "$TMP_CLEAN" 2>/dev/null && STATE_COUNT=$((STATE_COUNT + 1))
grep -qE '(focus-visible)' "$TMP_CLEAN" 2>/dev/null && STATE_COUNT=$((STATE_COUNT + 1))
grep -qE '(disabled:|:disabled|aria-disabled|\bdisabled=)' "$TMP_CLEAN" 2>/dev/null && STATE_COUNT=$((STATE_COUNT + 1))
grep -qE '(active:|:active)' "$TMP_CLEAN" 2>/dev/null && STATE_COUNT=$((STATE_COUNT + 1))

if   [ "$STATE_COUNT" -ge 4 ]; then STATE_SCORE=10
elif [ "$STATE_COUNT" -ge 3 ]; then STATE_SCORE=7
elif [ "$STATE_COUNT" -ge 2 ]; then STATE_SCORE=4
else STATE_SCORE=0
fi

# ---------- Single responsibility (5 pts) ----------
EXPORTS=$(count_matches '^export[[:space:]]+(default[[:space:]]+)?(function|const|class)[[:space:]]+[A-Z]' "$TMP_CLEAN")
if   [ "$EXPORTS" -le 2 ]; then SR_SCORE=5
else SR_SCORE=0
fi

# ---------- Total ----------
TOTAL=$((LOC_SCORE + COMPLEX_SCORE + TOKEN_SCORE + A11Y_SCORE + RESP_SCORE + STATE_SCORE + SR_SCORE))

if   [ "$TOTAL" -ge 90 ]; then GRADE="A"
elif [ "$TOTAL" -ge 75 ]; then GRADE="B"
elif [ "$TOTAL" -ge 60 ]; then GRADE="C"
else GRADE="F"
fi

cat <<EOF
{
  "file": "$FILE_PATH",
  "totalScore": $TOTAL,
  "grade": "$GRADE",
  "breakdown": {
    "loc":          { "score": $LOC_SCORE,     "max": 20, "value": $LOC },
    "complexity":   { "score": $COMPLEX_SCORE, "max": 20, "cyclomatic": $CYCLO, "jsxDepth": $DEPTH, "hooks": $HOOK_COUNT },
    "tokens":       { "score": $TOKEN_SCORE,   "max": 20, "hex": $HEX, "rgb": $RGB, "offScalePx": $BAD_PX, "primitiveRefs": $PRIMITIVE_REF },
    "a11y":         { "score": $A11Y_SCORE,    "max": 15, "issues": $A11Y_ISSUES },
    "responsive":   { "score": $RESP_SCORE,    "max": 10, "matches": $RESP },
    "states":       { "score": $STATE_SCORE,   "max": 10, "defined": $STATE_COUNT },
    "singleResp":   { "score": $SR_SCORE,      "max": 5,  "exports": $EXPORTS }
  }
}
EOF

[ "$TOTAL" -ge 60 ] && exit 0 || exit 1
