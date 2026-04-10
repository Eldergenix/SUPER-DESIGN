#!/usr/bin/env bash
# inject-design-context.sh — UserPromptSubmit hook.
# When the user's prompt contains design keywords, inject a pointer to
# DESIGN.md and the detected framework adapter into the agent's context.
#
# Safe: builds JSON via jq (or a sed-escape fallback), never via string
# interpolation into python/node.

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

PAYLOAD=$(cat 2>/dev/null || printf '{}')
PROMPT=$(read_json_field "$PAYLOAD" '.prompt')
CWD=$(read_json_field "$PAYLOAD" '.cwd')
[ -z "$CWD" ] && CWD="$PWD"

# Short-circuit: only fire on design-related prompts
if ! printf '%s' "$PROMPT" | grep -qiE '\b(style|styling|theme|themeing|ui|ux|component|design|screenshot|layout|responsive|token|color|colour|typograph|animation|transition|accessib|a11y|wcag|tailwind|shadcn|mui|radix|geist)\b'; then
  exit 0
fi

# Build context as plain text
CTX_FILE=$(mktemp)
trap 'rm -f "$CTX_FILE"' EXIT

{
  echo "📐 super-design skill is active. Follow the production design rules:"
  echo "  • Read DESIGN.md BEFORE editing UI. Use semantic tokens, never literal colors/unscaled px."
  echo "  • Every interactive element needs hover, focus-visible, active, disabled states."
  echo "  • :focus-visible only. Double-ring box-shadow for 3:1 contrast on any background."
  echo "  • Animate only transform and opacity; respect prefers-reduced-motion."
  echo "  • Max 300 LOC per component file; extract when larger."
  echo "  • Min 44x44 touch targets, 8px gap."
  echo "  • Test at 320/375/768/1024/1440/1920."
  echo "  • forced-colors: active fallback on interactive surfaces."
  echo ""

  if [ -f "$CWD/DESIGN.md" ]; then
    echo "✓ Project DESIGN.md detected at $CWD/DESIGN.md — read it first."
  else
    echo "⚠ No DESIGN.md in project root. Bootstrap the template or extract from a reference."
  fi

  # Framework hint
  if [ -f "$CWD/components.json" ] && grep -q 'tailwind' "$CWD/components.json" 2>/dev/null; then
    echo "✓ ShadCN detected → references/framework-adapters/shadcn.md"
  elif [ -f "$CWD/package.json" ]; then
    if grep -q '"@mui/material"' "$CWD/package.json" 2>/dev/null; then
      echo "✓ MUI detected → references/framework-adapters/mui.md"
    elif grep -q '"@radix-ui/themes"' "$CWD/package.json" 2>/dev/null; then
      echo "✓ Radix Themes detected → references/framework-adapters/radix.md"
    elif grep -q '"geist"' "$CWD/package.json" 2>/dev/null; then
      echo "✓ Geist detected → references/framework-adapters/geist.md"
    elif grep -qE '"@tailwindcss/(postcss|vite)"|"tailwindcss"[[:space:]]*:[[:space:]]*"\^?4' "$CWD/package.json" 2>/dev/null; then
      echo "✓ Tailwind v4 detected → references/framework-adapters/tailwind-v4.md"
    elif grep -q '"tailwindcss"' "$CWD/package.json" 2>/dev/null; then
      echo "✓ Tailwind v3 detected → references/framework-adapters/tailwind-v3.md"
    fi
  fi

  echo ""
  echo "Quality gate: bash scripts/test.sh <file>  → target score ≥ 90 (grade A)"
} > "$CTX_FILE"

# Emit JSON safely — jq handles escaping correctly
if command -v jq >/dev/null 2>&1; then
  jq -Rs '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: .
    }
  }' < "$CTX_FILE"
else
  # Fallback: python3 with stdin, no interpolation
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, sys
text = sys.stdin.read()
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'UserPromptSubmit',
    'additionalContext': text
  }
}))
" < "$CTX_FILE"
  else
    # Last resort: printf with manual escape
    esc=$(sed 's/\\/\\\\/g; s/"/\\"/g' "$CTX_FILE" | awk 'BEGIN{ORS="\\n"}{print}')
    printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$esc"
  fi
fi
