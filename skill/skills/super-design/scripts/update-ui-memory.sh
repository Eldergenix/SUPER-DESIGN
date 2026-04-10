#!/usr/bin/env bash
# update-ui-memory.sh — maintains a running log of every UI/UX code edit
# so the agent can reference past decisions and stay consistent across a
# long development cycle.
#
# Runs as PostToolUse hook on Edit|Write|MultiEdit, after the validators.
# Appends one structured entry per component write to:
#     ${CLAUDE_PROJECT_DIR}/.claude/super-design/ui-memory.md
#
# Entry format (markdown-friendly, agent-readable):
#
#   ## 2026-04-10T14:22:07Z — src/components/Button.tsx
#   - LOC: 42
#   - Tokens: --color-accent, --color-fg, --color-border, --radius-md, --inset-sm
#   - States: hover, focus-visible, disabled, active, loading
#   - Responsive: sm, md (2 breakpoints)
#   - Touch targets: compliant (min-h-11)
#   - Props interface: ButtonProps (exported)
#   - Forced-colors: compliant
#
# The memory file is bounded to the last 200 entries to keep it useful as
# context without growing unbounded. Entries older than the cap are
# truncated from the top of the file.
#
# This hook is ADVISORY — it never blocks a write. Its exit code is always 0.
# The file is injected into session context by inject-design-context.sh.

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

# Only track component/style files — same set as validate-component.sh
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte|*.astro|*.css|*.scss) ;;
  *) exit 0 ;;
esac

should_skip_file "$FILE_PATH" && exit 0

# Resolve memory location inside the project's .claude directory.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
MEMORY_DIR="${PROJECT_DIR}/.claude/super-design"
MEMORY_FILE="${MEMORY_DIR}/ui-memory.md"

mkdir -p "$MEMORY_DIR" 2>/dev/null || exit 0

# Relative path for the entry header (nicer than absolute)
REL_PATH="${FILE_PATH#${PROJECT_DIR}/}"

TMP_CLEAN=$(mktemp)
trap 'rm -f "$TMP_CLEAN"' EXIT
strip_comments "$FILE_PATH" > "$TMP_CLEAN"

# ---------- LOC ----------
LOC=$(awk 'NF' "$TMP_CLEAN" 2>/dev/null | wc -l | tr -d '[:space:]')
LOC=${LOC:-0}
[ "$LOC" -lt 3 ] && exit 0

# ---------- Tokens referenced ----------
# Extract unique --token-name occurrences. Limit to 8 to keep the entry compact.
TOKENS=$(grep -oE '\-\-[a-z][a-zA-Z0-9-]*' "$TMP_CLEAN" 2>/dev/null | sort -u | head -8 | tr '\n' ',' | sed 's/,$//; s/,/, /g')
[ -z "$TOKENS" ] && TOKENS="(none)"

# ---------- Interactive states ----------
STATES=()
grep -qE '(hover:|:hover)'                   "$TMP_CLEAN" 2>/dev/null && STATES+=("hover")
grep -qE '(focus-visible:|:focus-visible)'   "$TMP_CLEAN" 2>/dev/null && STATES+=("focus-visible")
grep -qE '(disabled:|:disabled|\bdisabled=)' "$TMP_CLEAN" 2>/dev/null && STATES+=("disabled")
grep -qE '(active:|:active)'                 "$TMP_CLEAN" 2>/dev/null && STATES+=("active")
grep -qE '(loading|aria-busy)'               "$TMP_CLEAN" 2>/dev/null && STATES+=("loading")
grep -qE '(aria-invalid|error)'              "$TMP_CLEAN" 2>/dev/null && STATES+=("error")
if [ "${#STATES[@]}" -eq 0 ]; then
  STATES_STR="(none)"
else
  STATES_STR=$(printf '%s, ' "${STATES[@]}" | sed 's/, $//')
fi

# ---------- Responsive breakpoints detected ----------
BPS=()
for bp in sm md lg xl 2xl; do
  if grep -qE "\b${bp}:" "$TMP_CLEAN" 2>/dev/null; then
    BPS+=("$bp")
  fi
done
CQUERY=""
if grep -qE '@container|container-type|container-name' "$TMP_CLEAN" 2>/dev/null; then
  CQUERY=" + container-queries"
fi
if [ "${#BPS[@]}" -eq 0 ] && [ -z "$CQUERY" ]; then
  RESPONSIVE_STR="(none)"
else
  RESPONSIVE_STR="$(printf '%s, ' "${BPS[@]}" | sed 's/, $//')${CQUERY}"
fi

# ---------- Touch targets ----------
TOUCH_STR="n/a"
if grep -qE '(onClick|onChange|onSubmit|<button|<input|<select|<a[[:space:]]|href=)' "$TMP_CLEAN" 2>/dev/null; then
  if grep -qE '(min-h-1[12]|min-w-1[12]|h-1[12]|w-1[12]|min-h-\[(4[4-9]|[5-9][0-9]+)px\]|min-height[[:space:]]*:[[:space:]]*(4[4-9]|[5-9][0-9]+)px)' "$TMP_CLEAN" 2>/dev/null; then
    TOUCH_STR="compliant (44×44 min)"
  else
    TOUCH_STR="⚠ not enforced"
  fi
fi

# ---------- Props interface ----------
PROPS_STR="n/a"
case "$FILE_PATH" in
  *.tsx|*.jsx)
    PROPS_NAME=$(grep -oE '(interface|type)[[:space:]]+[A-Z][A-Za-z0-9_]*Props\b' "$TMP_CLEAN" 2>/dev/null | head -1 | awk '{print $2}')
    if [ -n "$PROPS_NAME" ]; then
      if grep -qE "^[[:space:]]*export[[:space:]]+(interface|type)[[:space:]]+${PROPS_NAME}\b" "$TMP_CLEAN" 2>/dev/null; then
        PROPS_STR="${PROPS_NAME} (exported)"
      else
        PROPS_STR="${PROPS_NAME} (not exported)"
      fi
    elif grep -qE '(function|const)[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*(=[[:space:]]*\(\)|[[:space:]]*\(\))' "$TMP_CLEAN" 2>/dev/null; then
      PROPS_STR="(none needed — zero-prop component)"
    else
      PROPS_STR="⚠ missing"
    fi
    ;;
esac

# ---------- Forced-colors ----------
FC_STR="⚠ missing"
if grep -qE 'forced-colors' "$TMP_CLEAN" 2>/dev/null; then
  FC_STR="compliant"
fi

# ---------- Write the entry ----------
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
[ -z "$TIMESTAMP" ] && TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

ENTRY=$(cat <<ENTRY_EOF
## ${TIMESTAMP} — ${REL_PATH}
- LOC: ${LOC}
- Tokens: ${TOKENS}
- States: ${STATES_STR}
- Responsive: ${RESPONSIVE_STR}
- Touch targets: ${TOUCH_STR}
- Props interface: ${PROPS_STR}
- Forced-colors: ${FC_STR}
ENTRY_EOF
)

# Initialize the memory file with a header if it doesn't exist.
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" <<HEADER_EOF
# Super Design · UI Memory

Running log of every component write. Maintained automatically by
\`update-ui-memory.sh\` (PostToolUse hook). Most recent entries first.

This file is loaded into session context by \`inject-design-context.sh\`
so the agent can see its own past decisions and stay consistent with
token usage, state coverage, responsive patterns, and props interfaces
across the entire development cycle.

Bounded to the last 200 entries; older entries are pruned automatically.

---

HEADER_EOF
fi

# Prepend the new entry (after the header).
#
# Strategy: split the existing file into HEAD (everything up to but NOT
# including the first "## " line) and TAIL (the first "## " line and
# everything after). Write HEAD + new entry + blank line + TAIL.
#
# macOS awk can't take multi-line strings via -v, so we avoid awk for
# the insertion and use pure bash + sed instead.
TMP_OUT=$(mktemp)
TMP_HEAD=$(mktemp)
TMP_TAIL=$(mktemp)

# Find the line number of the first "## " header. If none, the whole file
# is the HEAD (no existing entries) and TAIL is empty.
FIRST_ENTRY_LINE=$(grep -n '^## ' "$MEMORY_FILE" 2>/dev/null | head -1 | cut -d: -f1)
if [ -z "$FIRST_ENTRY_LINE" ]; then
  cp "$MEMORY_FILE" "$TMP_HEAD"
  : > "$TMP_TAIL"
else
  HEAD_END=$((FIRST_ENTRY_LINE - 1))
  if [ "$HEAD_END" -gt 0 ]; then
    sed -n "1,${HEAD_END}p" "$MEMORY_FILE" > "$TMP_HEAD"
  else
    : > "$TMP_HEAD"
  fi
  sed -n "${FIRST_ENTRY_LINE},\$p" "$MEMORY_FILE" > "$TMP_TAIL"
fi

{
  cat "$TMP_HEAD"
  printf '%s\n\n' "$ENTRY"
  cat "$TMP_TAIL"
} > "$TMP_OUT" && mv "$TMP_OUT" "$MEMORY_FILE"

rm -f "$TMP_HEAD" "$TMP_TAIL"

# ---------- Bound the log to 200 entries ----------
# Count "## " headers (each is one entry). If > 200, trim from the bottom.
ENTRY_COUNT=$(grep -c '^## ' "$MEMORY_FILE" 2>/dev/null || true)
ENTRY_COUNT=${ENTRY_COUNT:-0}
if [ "$ENTRY_COUNT" -gt 200 ]; then
  # Keep: header (everything before first ##), plus first 200 entries.
  TMP_TRIM=$(mktemp)
  awk '
    BEGIN { in_body = 0; entries = 0 }
    /^## / { entries++; in_body = 1 }
    {
      if (in_body && entries > 200) exit
      print
    }
  ' "$MEMORY_FILE" > "$TMP_TRIM" && mv "$TMP_TRIM" "$MEMORY_FILE"
fi

# Never block the edit.
exit 0
