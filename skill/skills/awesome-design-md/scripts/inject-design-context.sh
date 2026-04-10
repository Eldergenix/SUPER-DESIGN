#!/usr/bin/env bash
# inject-design-context.sh — UserPromptSubmit hook.
# When the user's prompt contains design keywords, inject a pointer to
# DESIGN.md and the detected framework adapter into the agent's context.

set -eo pipefail

PAYLOAD=$(cat)
PROMPT=$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("prompt",""))' 2>/dev/null || echo "")

# Skip if prompt doesn't mention any design-related keyword
if ! printf '%s' "$PROMPT" | grep -qiE '\b(style|theme|ui|ux|component|design|screenshot|layout|responsive|token|color|typograph|animation|transition|accessib|a11y|wcag|tailwind|shadcn|mui|radix|geist)\b'; then
  exit 0
fi

CWD=$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("cwd","."))' 2>/dev/null || echo ".")

CONTEXT=""
CONTEXT+="📐 awesome-design-md skill is active. Follow the production design rules:"$'\n'
CONTEXT+="  • Read \`DESIGN.md\` BEFORE editing UI. Use tokens, never literal colors/px."$'\n'
CONTEXT+="  • Every interactive element needs hover, focus-visible, active, disabled states."$'\n'
CONTEXT+="  • \`:focus-visible\` only. 3px outline, 2px offset, 3:1 contrast."$'\n'
CONTEXT+="  • Animate only \`transform\` and \`opacity\`; respect \`prefers-reduced-motion\`."$'\n'
CONTEXT+="  • Max 300 LOC per component file; extract when larger."$'\n'
CONTEXT+="  • Test at 320/375/768/1024/1440/1920."$'\n'
CONTEXT+=""$'\n'

# Check for DESIGN.md in project
if [ -f "$CWD/DESIGN.md" ]; then
  CONTEXT+="✓ Project DESIGN.md detected at \`$CWD/DESIGN.md\` — read it first."$'\n'
else
  CONTEXT+="⚠ No DESIGN.md in project root. Use the enhanced template at \`\${CLAUDE_SKILL_DIR}/DESIGN.md\` or ask the user to pick a reference."$'\n'
fi

# Detect framework adapter to hint at
if [ -f "$CWD/components.json" ] && grep -q 'tailwind' "$CWD/components.json" 2>/dev/null; then
  CONTEXT+="✓ ShadCN detected → use \`references/framework-adapters/shadcn.md\`"$'\n'
elif [ -f "$CWD/package.json" ]; then
  if grep -q '"@mui/material"' "$CWD/package.json"; then
    CONTEXT+="✓ MUI detected → use \`references/framework-adapters/mui.md\`"$'\n'
  elif grep -q '"@radix-ui/themes"' "$CWD/package.json"; then
    CONTEXT+="✓ Radix Themes detected → use \`references/framework-adapters/radix.md\`"$'\n'
  elif grep -q '"geist"' "$CWD/package.json"; then
    CONTEXT+="✓ Geist detected → use \`references/framework-adapters/geist.md\`"$'\n'
  elif grep -qE '"@tailwindcss/(postcss|vite)"|"tailwindcss"\s*:\s*"\^?4' "$CWD/package.json"; then
    CONTEXT+="✓ Tailwind v4 detected → use \`references/framework-adapters/tailwind-v4.md\`"$'\n'
  elif grep -q '"tailwindcss"' "$CWD/package.json"; then
    CONTEXT+="✓ Tailwind v3 detected → use \`references/framework-adapters/tailwind-v3.md\`"$'\n'
  fi
fi

CONTEXT+=""$'\n'"Quality gates: \`bash \${CLAUDE_SKILL_DIR}/scripts/quality-score.sh <file>\` — target score ≥ 90 (grade A)."$'\n'

# Emit via JSON for UserPromptSubmit hook
python3 -c "
import json, sys
ctx = '''$CONTEXT'''
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'UserPromptSubmit',
    'additionalContext': ctx
  }
}))
"
