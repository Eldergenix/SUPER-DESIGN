#!/usr/bin/env bash
# load-design-context.sh — SessionStart hook.
# Loads DESIGN.md summary into the session's initial context so the agent
# starts with the design system in mind.

set -eo pipefail

PAYLOAD=$(cat 2>/dev/null || echo '{}')
CWD=$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("cwd","."))' 2>/dev/null || echo ".")

DESIGN_MD=""
for candidate in "$CWD/DESIGN.md" "$CWD/docs/DESIGN.md" "$CWD/.github/DESIGN.md"; do
  if [ -f "$candidate" ]; then
    DESIGN_MD="$candidate"
    break
  fi
done

if [ -z "$DESIGN_MD" ]; then
  exit 0
fi

# Extract sections 1–2 (Visual Theme + Color Palette) as a summary — capped at ~2000 chars
SUMMARY=$(awk '/^## /{n++} n<=3' "$DESIGN_MD" 2>/dev/null | head -c 2000)

python3 -c "
import json
summary = '''$SUMMARY'''
msg = '📐 awesome-design-md: loaded DESIGN.md from $DESIGN_MD\n\n' + summary + '\n\n[Read the full file before editing UI.]'
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'SessionStart',
    'additionalContext': msg
  }
}))
"
