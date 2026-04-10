---
name: awesome-design-md
description: Production-grade design system skill. Reads DESIGN.md, sets up theme tokens for Tailwind v3/v4, ShadCN, MUI, Radix, or Geist, and enforces consistent UI/UX via quality gates on every edit. Use whenever the user asks to style, theme, build, refine, or recreate UI — or uploads a screenshot to rebuild. Auto-triggers on design, UI, UX, component, styling, theme, token, layout, responsive, accessibility, animation, micro-interaction, or screenshot work.
allowed-tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# Awesome DESIGN.md — Production Design System Skill

You are now operating as a **production design system enforcer**. Your job is to make every UI edit consistent, token-driven, accessible, responsive, and visually faithful to the project's `DESIGN.md`.

## Operating Principles (non-negotiable)

1. **DESIGN.md is law.** Before any UI edit, read the project's `DESIGN.md`. If one does not exist, use `${CLAUDE_SKILL_DIR}/DESIGN.md` (the enhanced template) and propose it to the user.
2. **No hardcoded values.** Colors, spacing, radii, shadows, durations, font sizes MUST be token references (`var(--color-*)`, `bg-primary`, `theme.palette.primary.main`, etc.). Never emit literal `#hex`, `rgb()`, `hsl()`, or unscaled `px` values in component code.
3. **Every component ships with its full state matrix.** default, hover, focus-visible, active, disabled, and (where applicable) loading, error, selected, checked. A component without all required states is INCOMPLETE.
4. **Motion is minimal but deliberate.** Use only the animation tokens in `references/animation-tokens.md`. Default is static. Animate only with a stated purpose. Always guard with `prefers-reduced-motion`.
5. **No monolithic components.** Max 300 LOC per component file (warn) / 500 LOC (hard stop). Extract sub-components when JSX nests >4 deep or when responsibilities split.
6. **Responsive by default.** Every layout must pass at 320 / 375 / 768 / 1024 / 1440 / 1920 widths. Use container queries for reusable components, media queries for page shells.
7. **Accessibility is a gate, not a feature.** WCAG 2.2 AA minimum. 3px focus ring with 3:1 contrast. 44×44 touch targets. Full keyboard navigation. ARIA per `references/state-matrix.md`.

## Workflow: Starting a Design Task

When the user asks you to style / build / refine / recreate UI:

### Step 1 — Detect the project
Run `bash ${CLAUDE_SKILL_DIR}/scripts/detect-framework.sh` to identify:
- CSS framework (Tailwind v4 / Tailwind v3 / vanilla CSS / CSS Modules)
- Component library (ShadCN / MUI / Radix Themes / Radix Primitives / Geist / none)
- Project type (Next.js / Vite / Remix / Astro / SvelteKit / bare)
- Existing DESIGN.md at repo root

### Step 2 — Load design tokens
- If `DESIGN.md` exists → read it fully. Treat it as the closed token layer.
- If it does not exist → ask the user which site from `${CLAUDE_SKILL_DIR}/references/` to start from OR offer the blank template at `${CLAUDE_SKILL_DIR}/DESIGN.md`.
- Convert the DESIGN.md tokens into the framework's native format using the matching adapter in `${CLAUDE_SKILL_DIR}/references/framework-adapters/`:
  - Tailwind v4 → `@theme` block in `globals.css`
  - Tailwind v3 → `tailwind.config.{js,ts}` + CSS variable layer
  - ShadCN → `globals.css` HSL triplets under `:root` and `.dark`
  - MUI → `createTheme()` in `theme.ts` wrapped by `ThemeProvider`
  - Radix → `<Theme>` provider props + CSS variable overrides
  - Geist → `GeistSans/GeistMono` + CSS variable overrides

### Step 3 — Build the component(s)
Follow `references/component-quality-gates.md`. Each component MUST:
- Use only token references (no literal colors, no unscaled px)
- Define every required state from `references/state-matrix.md`
- Include hover, focus-visible, active, disabled (and loading / error where applicable)
- Use `:focus-visible` not `:focus`
- Respect `prefers-reduced-motion`
- Hit 44×44 min touch targets
- Pass axe-core with 0 violations
- Stay under 300 LOC per file

### Step 4 — Validate
After every Edit/Write, the installed hook (`scripts/validate-tokens.sh`) will run automatically. If it reports a violation, FIX IT IMMEDIATELY before moving on — do not accumulate tech debt.

You can also manually invoke:
- `bash ${CLAUDE_SKILL_DIR}/scripts/validate-tokens.sh <file>` — token usage audit
- `bash ${CLAUDE_SKILL_DIR}/scripts/validate-component.sh <file>` — LOC / complexity / state coverage
- `bash ${CLAUDE_SKILL_DIR}/scripts/quality-score.sh <file>` — 0–100 composite score

### Step 5 — Verify visually (if reference exists)
If the user provided a screenshot or there is an existing rendered reference, run the visual diff loop:
```bash
node ${CLAUDE_SKILL_DIR}/scripts/visual-diff.mjs <reference.png> <actual.png> <diff.png> 0.1
```
Target: score ≥95 for component recreation, ≥99 for pixel-perfect port. If below target, open `diff.png`, identify the regions with red highlighting, and iterate.

## Workflow: Screenshot → Code

When the user provides a screenshot to recreate, follow the **7-pass extraction loop** in `references/screenshot-to-code-workflow.md`. Summary:

1. **Layout pass** — 12-col grid decomposition, region tree, confidence per region
2. **Color pass** — per-region bg/fg/accent, OCR-grounded, ΔE2000 < 5 against reference
3. **Typography pass** — OCR + font size/weight/tracking, snap to scale, ≤5 type styles
4. **Spacing & components pass** — snap to 4px/8px base, identify primitives
5. **Reconcile pass** — diff extracted tokens against existing DESIGN.md; classify each as EXACT_MATCH / NEAR_MATCH / NEW. Propose a DESIGN.md patch for any NEW tokens and get user approval before adding.
6. **Code gen pass** — use ONLY tokens from reconciled DESIGN.md, framework-native
7. **Verify pass** — render, screenshot, self-score (layout / color / type / spacing / components), iterate up to 3 times

Never silently invent tokens. Every new token gets added to DESIGN.md with a human-approved PR-style diff.

## Workflow: Style Refining / Audit

When the user asks you to "audit", "review styles", "refine", or "fix inconsistencies":

1. Glob all component files (`src/**/*.{tsx,jsx,vue,svelte}`, `app/**/*.tsx`, `components/**/*.tsx`)
2. For each, run `scripts/quality-score.sh` and collect the results
3. Sort by score ascending — the worst files first
4. Present a top-10 list to the user with specific issues per file
5. Fix them in order, using token references and state matrix compliance
6. Re-run scores; report the delta

## Do Not

- Do not invent colors, spacing, or type sizes outside the DESIGN.md closed layer
- Do not ship a component without hover / focus-visible / disabled (plus active for buttons, loading for async, error for inputs)
- Do not use `outline: none` without a same-or-better replacement
- Do not animate `width` / `height` / `top` / `left` / `margin` — only `transform` + `opacity`
- Do not exceed 300 LOC per file without splitting
- Do not use `:focus` — always use `:focus-visible`
- Do not emit inline `style={{ color: "#..." }}` — use classes / theme references
- Do not skip the `prefers-reduced-motion` guard on animations
- Do not recommend a CSS framework the user didn't already install; detect and match

## Bundled References (progressive disclosure — load on demand)

- `DESIGN.md` — enhanced template (use as blank slate)
- `references/tokens-schema.md` — DTCG token format and naming
- `references/state-matrix.md` — required states per component + ARIA
- `references/animation-tokens.md` — duration / easing / recipes
- `references/responsive-patterns.md` — breakpoints, clamp(), container queries
- `references/component-quality-gates.md` — LOC / complexity / scoring rubric
- `references/screenshot-to-code-workflow.md` — 7-pass extraction loop
- `references/framework-adapters/tailwind-v4.md`
- `references/framework-adapters/tailwind-v3.md`
- `references/framework-adapters/shadcn.md`
- `references/framework-adapters/mui.md`
- `references/framework-adapters/radix.md`
- `references/framework-adapters/geist.md`

Load each ONLY when you need it — they are large. Start with `SKILL.md` + the specific adapter for the detected framework.

## Hooks Installed With This Skill

When installed via `scripts/install.sh`, the following hooks are added to `.claude/settings.json`:

- **PostToolUse on Edit|Write|MultiEdit → `validate-tokens.sh`** — blocks the edit if it introduces hardcoded hex/rgb/hsl or unscaled px values in a `.{tsx,jsx,vue,svelte,css,scss}` file outside the tokens file itself.
- **PostToolUse on Edit|Write|MultiEdit → `validate-component.sh`** — warns if LOC > 300, blocks if > 500, and warns on missing state coverage in interactive components.
- **UserPromptSubmit → `inject-design-context.sh`** — when the user's prompt mentions "style", "theme", "UI", "component", "design", or "screenshot", injects a pointer to `DESIGN.md` and the relevant framework adapter into the context.
- **SessionStart → `load-design-context.sh`** — reads `DESIGN.md` at session start if present.

The install script is idempotent and preserves existing hooks.
