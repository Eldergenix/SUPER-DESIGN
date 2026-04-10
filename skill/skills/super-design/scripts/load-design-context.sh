#!/usr/bin/env bash
# load-design-context.sh — SessionStart hook.
# Injects a summary of the project's DESIGN.md into the session context.
# Safe JSON building via jq (or python3 fallback).

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

PAYLOAD=$(cat 2>/dev/null || printf '{}')
CWD=$(read_json_field "$PAYLOAD" '.cwd')
[ -z "$CWD" ] && CWD="$PWD"

DESIGN_MD=""
for candidate in "$CWD/DESIGN.md" "$CWD/docs/DESIGN.md" "$CWD/.github/DESIGN.md"; do
  if [ -f "$candidate" ]; then
    DESIGN_MD="$candidate"
    break
  fi
done

[ -z "$DESIGN_MD" ] && exit 0

# Take first 3 sections, respecting line boundaries, cap at ~2000 chars
CTX_FILE=$(mktemp)
trap 'rm -f "$CTX_FILE"' EXIT

{
  printf '📐 super-design loaded DESIGN.md from %s\n\n' "$DESIGN_MD"
  awk '/^## /{n++} n>3{exit} {print}' "$DESIGN_MD" | awk '
    BEGIN {len=0; max=1800}
    {
      if (len + length($0) + 1 > max) { print "..."; exit }
      print $0
      len += length($0) + 1
    }'
  printf '\n\n[Read the full file before editing UI. Use tokens, not literals.]\n'
} > "$CTX_FILE"

if command -v jq >/dev/null 2>&1; then
  jq -Rs '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: .
    }
  }' < "$CTX_FILE"
else
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, sys
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'SessionStart',
    'additionalContext': sys.stdin.read()
  }
}))
" < "$CTX_FILE"
  fi
fi
