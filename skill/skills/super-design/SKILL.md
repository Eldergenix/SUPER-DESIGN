---
name: super-design
description: Use when the user asks you to build, style, theme, refine, audit, or recreate UI — or uploads a screenshot to rebuild. Reads DESIGN.md as a closed token layer, detects the project's framework (Tailwind v4/v3, ShadCN, MUI, Radix, Geist), and enforces production design rules (tokens only, full state matrix, WCAG 2.2 AA, responsive, minimal motion, max 300 LOC/component) via PostToolUse hooks.
allowed-tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# Super Design

You enforce a production design system. Read `DESIGN.md` before editing UI. Emit tokens, never literals. Ship full state coverage. Validate with the bundled scripts.

## The one-paragraph rule

Any UI code you write references `DESIGN.md` tokens by name. No `#hex`, no `rgb()/hsl()`, no raw `px` outside the scale, no inline `style={{ color: ... }}`. Every interactive element defines `hover`, `focus-visible`, `active`, `disabled` — buttons add `loading`, inputs add `error` and `readonly`. Focus rings use `:focus-visible` with a double-layer box-shadow for 3:1 contrast at all offsets. Motion is `transform` and `opacity` only, under 300ms, guarded by `prefers-reduced-motion`. Files stay under 300 LOC. Layouts pass at 320/375/768/1024/1440/1920. Run `bash scripts/test.sh <file>` before declaring done — target score ≥ 90.

## Before / after — the discipline in 5 seconds

**❌ Rejected by the hook:**
```tsx
<button
  style={{ background: '#5e6ad2', padding: '17px' }}
  className="rounded-[6px] hover:bg-[#828fff]"
  onClick={submit}
>
  Save
</button>
```
Rejected for: literal hex (×2), off-scale px, arbitrary Tailwind value, no `:focus-visible`, no `:disabled`, no `:active`, no min size, no `type`, no `aria-busy` on async click.

**✓ Accepted:**
```tsx
<Button variant="primary" size="md" loading={isPending} onClick={submit}>
  Save
</Button>
```
With a `Button` that reads:
```tsx
// components/ui/button.tsx — 92 LOC
const buttonVariants = cva(
  [
    "inline-flex items-center justify-center gap-2 whitespace-nowrap",
    "rounded-md font-medium select-none",
    "transition-[background-color,box-shadow,transform] duration-fast ease-out",
    "focus-visible:outline-none",
    "focus-visible:shadow-[0_0_0_2px_var(--color-bg),0_0_0_5px_var(--color-focus-ring)]",
    "active:scale-[0.98]",
    "disabled:opacity-50 disabled:pointer-events-none",
    "aria-busy:opacity-70 aria-busy:cursor-wait",
    "forced-colors:border forced-colors:border-[ButtonText]",
    "min-h-11 min-w-11",
  ].join(" "),
  {
    variants: {
      variant: {
        primary:   "bg-accent text-accent-fg hover:bg-accent-hover",
        secondary: "bg-surface text-fg border border-border hover:bg-surface-raised",
        ghost:     "bg-transparent text-fg hover:bg-surface-raised",
        danger:    "bg-danger text-white hover:brightness-110",
      },
      size: { sm: "h-9 px-3 text-sm", md: "h-11 px-4", lg: "h-12 px-6 text-base" },
    },
    defaultVariants: { variant: "primary", size: "md" },
  }
);
```

Every token resolves through `DESIGN.md`. No magic numbers.

## Workflow: starting a UI task

**Step 1 — Detect.**
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/detect-framework.sh"
```
Returns JSON with `cssFramework`, `tailwindVersion`, `componentLibrary`, `projectFramework`, `designMd`. Branch on `recommendedAdapter`.

**Step 2 — Load DESIGN.md.**
- If it exists → read it completely.
- If it doesn't → ask: *"I don't see DESIGN.md. Do you want me to (a) bootstrap the template, (b) extract one from a reference in the `super-design` collection, or (c) extract one from a screenshot?"* Do not proceed without a closed token layer.

**Step 3 — Lint the DESIGN.md.**
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/lint-design-md.sh" DESIGN.md
```
If it fails schema, stop and fix it first. A broken token layer poisons everything downstream.

**Step 4 — Generate theme (once per project).**
```bash
node "${CLAUDE_SKILL_DIR}/scripts/generate-theme.mjs" DESIGN.md --target=<adapter>
```
Emits the framework-native theme file (`@theme` block, `tailwind.config.ts`, `theme.ts`, etc.) wired to the tokens in DESIGN.md. Show the user the diff; get approval before writing.

**Step 5 — Build the component.**
- Max 300 LOC per file; extract when you approach it.
- Every required state from `references/state-matrix.md`.
- Use the matching adapter in `references/framework-adapters/`.
- Use `:focus-visible` with the double-ring shadow pattern.
- Touch targets ≥ 44×44.
- Mark interactive text with `select-none`; mark inert overlays with `pointer-events-none`.

**Step 6 — Validate.**
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/test.sh" <file>
```
Runs `validate-tokens`, `validate-component`, `quality-score`, and — if a reference PNG exists — `visual-diff`. Blocks on violations; warns on smells; emits a composite score 0–100.

**Step 7 — Verify contrast.**
```bash
node "${CLAUDE_SKILL_DIR}/scripts/contrast-check.mjs" DESIGN.md
```
Walks every semantic color pair (fg on bg, accent-fg on accent, border on surface) and asserts WCAG 2.2 AA (4.5:1 text, 3:1 large text + UI, 3:1 focus).

## Workflow: screenshot → code

Follow `references/screenshot-to-code-workflow.md`. The 7-pass loop is encoded as filled prompts with concrete JSON schemas. Do not invent tokens — reconcile against DESIGN.md at pass 5 and get user approval on any NEW tokens.

For dense regions:
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/crop-region.sh" input.png <x> <y> <w> <h> out.png
```
Crops produce measurably better vision-model accuracy. Use them.

For verification:
```bash
node "${CLAUDE_SKILL_DIR}/scripts/screenshot-component.mjs" http://localhost:3000/my-page out.png
node "${CLAUDE_SKILL_DIR}/scripts/visual-diff.mjs" reference.png out.png diff.png 0.1
```
Iterate until `score ≥ 95` (recreation) or `≥ 99` (pixel-perfect port). Cap at 3 iterations — gains plateau.

## Workflow: style audit

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/audit.sh" src/
```
Walks every component file, emits `{file, score, grade, violations[]}`, sorts by worst. Fix in order. Re-run and report the delta.

## Model-specific notes

- **Claude (3.5/4.x)** — strongest at layout + OCR + iteration. Give it crops for dense regions.
- **GPT-4o / GPT-5** — strong on component identification. Weak on exact bbox coords; use the 12-grid overlay prompt.
- **Gemini 1.5+** — native bbox output; can skip grid overlay. Strong on long-context multi-screen flows.
- **All models** — never trust guessed text. Always OCR-ground typography.

## Hard stops (the hook blocks these)

| Violation | Exit |
|---|---|
| Literal `#hex`/`rgb()`/`hsl()` outside token file | block |
| Inline `style={{ color: ... }}` | block |
| `<img>` without `alt` | block |
| File > 500 LOC | block |
| File with no `focus-visible` but has `onClick`/`<button>` | block |
| `outline: none` without replacement shadow/outline | warn |
| Animating `width`/`height`/`top`/`left`/`margin`/`padding` | warn |
| px outside the allowed scale (> 3 occurrences) | block |
| Component file with > 12 hooks | block |

Allowed px scale: `0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 56, 64, 72, 80, 96, 112, 128, 160, 192, 224, 256`, plus viewport breakpoints `320, 375, 768, 1024, 1280, 1440, 1536, 1920`.

## Bundled files — progressive disclosure

Load on demand; each reference is ~400–900 words:

- `DESIGN.md` — the enhanced template (blank slate)
- `references/tokens-schema.md` — DTCG format, naming, primitive vs semantic vs component layers
- `references/state-matrix.md` — required states per component + ARIA + keyboard + `STATE_MATRIX.yaml`
- `references/animation-tokens.md` — duration/easing/recipes + reduced-motion
- `references/responsive-patterns.md` — breakpoints, clamp(), container queries, touch targets, safe-area
- `references/component-quality-gates.md` — LOC/complexity/scoring rubric + regex patterns
- `references/screenshot-to-code-workflow.md` — 7-pass extraction loop with filled prompts
- `references/framework-adapters/*.md` — concrete theme codegen per framework

Only load what you need. SKILL.md + the single matching adapter is typically enough for one session.

## Do not

- Do not invent tokens. Propose a diff to DESIGN.md and wait for approval.
- Do not reference primitive tokens (`--color-neutral-900`) from components. Reference the semantic layer (`--color-fg`).
- Do not use `:focus` — always `:focus-visible` with a double-ring.
- Do not use `outline: none` without a same-or-greater-visibility replacement.
- Do not ship without a `forced-colors: active` fallback on interactive surfaces.
- Do not generate theme files if DESIGN.md is failing the linter.
- Do not skip `lint-design-md.sh` at session start.
- Do not write > 300 LOC/component without splitting.
- Do not animate layout properties.
- Do not auto-loop visual-diff more than 3 times without surfacing to the user.
