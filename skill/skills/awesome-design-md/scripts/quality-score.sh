#!/usr/bin/env bash
# quality-score.sh — 0-100 composite score for a component file.
# Usage: bash quality-score.sh path/to/Component.tsx
#
# Note: this is a reporting script; it intentionally does NOT use `set -e`
# because many of its checks legitimately use grep predicates that return
# non-zero when no match is found.

set +e

FILE_PATH="${1:-}"
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  echo '{"error":"file not found","file":"'"$FILE_PATH"'"}' >&2
  exit 1
fi

# Helper: grep count that always returns a single integer
count() {
  local c
  c=$(grep -cE "$1" "$2" 2>/dev/null || true)
  echo "${c:-0}" | head -1
}

# ---------- LOC (20 pts) ----------
LOC=$(awk '!/^[[:space:]]*$/' "$FILE_PATH" 2>/dev/null | wc -l | tr -d ' ')
LOC=${LOC:-0}
if   [ "$LOC" -le 200 ]; then LOC_SCORE=20
elif [ "$LOC" -le 300 ]; then LOC_SCORE=15
elif [ "$LOC" -le 500 ]; then LOC_SCORE=8
else LOC_SCORE=0
fi

# ---------- Complexity (20 pts) ----------
# Rough cyclomatic: count if/else/for/while/case/&&/||/?:
CYCLO=$(count '\b(if|else[[:space:]]+if|for|while|case)\b|&&|\|\||\?[[:space:]]*[^:]+:' "$FILE_PATH")
# Cognitive proxy: nested indent depth on control-flow lines
NESTED=$(awk '/^[[:space:]]*(if|for|while)/ { d=0; for(i=1;i<=length($0);i++) if(substr($0,i,1)==" ") d++; else break; if(d>m) m=d } END{print m+0}' "$FILE_PATH")
NESTED=${NESTED:-0}
if   [ "$CYCLO" -le 10 ] && [ "$NESTED" -le 8 ];  then COMPLEX_SCORE=20
elif [ "$CYCLO" -le 15 ] && [ "$NESTED" -le 12 ]; then COMPLEX_SCORE=10
else COMPLEX_SCORE=0
fi

# ---------- Token usage (20 pts) ----------
HEX=$(count '#([0-9a-fA-F]{3}){1,2}\b' "$FILE_PATH")
RGB=$(count '\b(rgb|rgba|hsl|hsla)[[:space:]]*\(' "$FILE_PATH")
BAD_PX=$(grep -oE '\b[0-9]+px\b' "$FILE_PATH" 2>/dev/null | \
          grep -vE '^(0|1|2|3|4|6|8|10|12|14|16|20|24|28|32|36|40|44|48|56|64|72|80|96|112|128|160|192|224|256)px$' 2>/dev/null | \
          wc -l | tr -d ' ')
BAD_PX=${BAD_PX:-0}
TOTAL_LITERALS=$((HEX + RGB + BAD_PX))
if   [ "$TOTAL_LITERALS" -eq 0 ]; then TOKEN_SCORE=20
elif [ "$TOTAL_LITERALS" -le 2 ]; then TOKEN_SCORE=10
else TOKEN_SCORE=0
fi

# ---------- A11y (15 pts) ----------
A11Y_ISSUES=0
# <img without alt (both grep calls must succeed; short-circuit with || true)
if { grep -nE '<img' "$FILE_PATH" 2>/dev/null | grep -qv 'alt=' 2>/dev/null; } && \
   grep -qE '<img' "$FILE_PATH" 2>/dev/null; then
  A11Y_ISSUES=$((A11Y_ISSUES+1))
fi
# onClick without keyboard handler on non-button element
if grep -qE 'onClick' "$FILE_PATH" 2>/dev/null && ! grep -qE 'onKey(Down|Up|Press)' "$FILE_PATH" 2>/dev/null; then
  A11Y_ISSUES=$((A11Y_ISSUES+1))
fi
# File has zero a11y markers at all (penalizes "forgot aria" cases)
if ! grep -qE 'aria-|alt=|role=|<button|<a[[:space:]]|<label' "$FILE_PATH" 2>/dev/null; then
  # Only penalize if the file actually has interactive elements
  if grep -qE 'onClick|onChange|onSubmit' "$FILE_PATH" 2>/dev/null; then
    A11Y_ISSUES=$((A11Y_ISSUES+1))
  fi
fi

if   [ "$A11Y_ISSUES" -eq 0 ]; then A11Y_SCORE=15
elif [ "$A11Y_ISSUES" -le 2 ]; then A11Y_SCORE=8
else A11Y_SCORE=0
fi

# ---------- Responsive (10 pts) ----------
RESP_COUNT=$(count '(sm:|md:|lg:|xl:|@container|@media|clamp\()' "$FILE_PATH")
if   [ "$RESP_COUNT" -ge 3 ]; then RESP_SCORE=10
elif [ "$RESP_COUNT" -ge 1 ]; then RESP_SCORE=5
else RESP_SCORE=0
fi

# ---------- States defined (10 pts) ----------
STATE_COUNT=0
grep -qE '(hover:|:hover)' "$FILE_PATH" && STATE_COUNT=$((STATE_COUNT+1))
grep -qE '(focus-visible:|:focus-visible)' "$FILE_PATH" && STATE_COUNT=$((STATE_COUNT+1))
grep -qE '(disabled:|:disabled|aria-disabled)' "$FILE_PATH" && STATE_COUNT=$((STATE_COUNT+1))
grep -qE '(active:|:active)' "$FILE_PATH" && STATE_COUNT=$((STATE_COUNT+1))

if   [ "$STATE_COUNT" -ge 3 ]; then STATE_SCORE=10
elif [ "$STATE_COUNT" -ge 2 ]; then STATE_SCORE=6
else STATE_SCORE=0
fi

# ---------- Single responsibility (5 pts) ----------
EXPORTS=$(count '^export[[:space:]]+(default[[:space:]]+)?(function|const)[[:space:]]+[A-Z]' "$FILE_PATH")
if [ "$EXPORTS" -le 2 ]; then SR_SCORE=5; else SR_SCORE=0; fi

# ---------- Total ----------
TOTAL=$((LOC_SCORE + COMPLEX_SCORE + TOKEN_SCORE + A11Y_SCORE + RESP_SCORE + STATE_SCORE + SR_SCORE))

# Grade
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
    "complexity":   { "score": $COMPLEX_SCORE, "max": 20, "cyclomatic": $CYCLO, "nested": $NESTED },
    "tokens":       { "score": $TOKEN_SCORE,   "max": 20, "hexLiterals": $HEX, "rgbLiterals": $RGB, "offScalePx": $BAD_PX },
    "a11y":         { "score": $A11Y_SCORE,    "max": 15, "issues": $A11Y_ISSUES },
    "responsive":   { "score": $RESP_SCORE,    "max": 10, "matches": $RESP_COUNT },
    "states":       { "score": $STATE_SCORE,   "max": 10, "defined": $STATE_COUNT },
    "singleResp":   { "score": $SR_SCORE,      "max": 5,  "exports": $EXPORTS }
  }
}
EOF
