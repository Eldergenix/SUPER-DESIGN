# AGENTS.md

> Universal agent instructions. Read by Claude Code, Cursor, OpenAI Codex,
> GitHub Copilot, Gemini CLI, Google Antigravity, Windsurf, Zed, Cline,
> Continue.dev, Aider. The design-system subset of these instructions is
> enforced by the **awesome-design-md** skill.

## Design System

This project has a `DESIGN.md` at the root. **READ IT BEFORE TOUCHING UI.** It
is the closed token layer — every color, spacing, typography, radius, shadow,
and animation value in component code MUST reference a token defined there.

Do not invent values. If you need a token that doesn't exist, propose adding
it to `DESIGN.md` first and get approval before using it.

## Hard Rules (non-negotiable, enforced by hook)

1. **No hardcoded values** in component code — no `#hex`, no `rgb()`, no
   `hsl()`, no unscaled `px`. Reference a token.
2. **Every interactive element** defines `hover`, `focus-visible`, `active`,
   and `disabled` states. Buttons also need `loading`. Inputs also need
   `error` and `readonly`.
3. **Use `:focus-visible`** for keyboard focus rings. Never plain `:focus`.
   Standard: 3px outline, 2px offset, 3:1 contrast.
4. **Animate only `transform` and `opacity`.** Never animate `width`,
   `height`, `top`, `left`, `margin`, or `padding`.
5. **Respect `prefers-reduced-motion`.** Replace movement with opacity
   changes, don't kill all motion.
6. **Max 300 LOC per component file** (warn) / **500 LOC** (hard stop).
   Extract sub-components when JSX nests > 4 levels deep.
7. **Min 44×44 touch targets.** 8px minimum gap between targets.
8. **Responsive.** Every layout must work at 320 / 375 / 768 / 1024 / 1440 /
   1920. Use container queries for reusable components, media queries for
   page shells.

## Workflow

1. Read `DESIGN.md` first
2. Detect the framework (Tailwind v4 / v3, ShadCN, MUI, Radix, Geist) and use
   the matching adapter in
   `.claude/skills/awesome-design-md/references/framework-adapters/`
3. Build the component using tokens only
4. Self-check against `references/component-quality-gates.md`
5. Run `bash .claude/skills/awesome-design-md/scripts/quality-score.sh <file>`
   — target score ≥ 90 (grade A)

## Screenshot → Code

If the user provides a screenshot to recreate, follow the 7-pass extraction
loop in `.claude/skills/awesome-design-md/references/screenshot-to-code-workflow.md`.
Never silently invent tokens — reconcile against DESIGN.md first.

## Full Skill

Bundled at `.claude/skills/awesome-design-md/SKILL.md`. Load the skill's
reference files on demand; they are large.
