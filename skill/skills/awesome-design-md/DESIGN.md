# Design System: [PROJECT NAME]

> This is the enhanced DESIGN.md template for the **awesome-design-md** skill.
> It extends Google Stitch's DESIGN.md format with production-grade sections for
> AI agents: closed token layers, state matrices, animation tokens, responsive
> patterns, quality gates, and screenshot-recreation rules.
>
> **AI AGENT RULE:** Every value in component code MUST reference a token from
> this file. Never emit literal `#hex`, `rgb()`, `hsl()`, or unscaled `px`
> values in component code. If a needed value is not defined here, PROPOSE an
> addition to this file and get approval BEFORE using it.

**Brand narrative** (3–5 sentences describing mood, personality, and tone):

> [Write the narrative here — what the design system feels like. This is the
> ONE place where prose beats structure. Keep it short, evocative, and specific.]

---

## 0. Meta

| Field | Value |
|---|---|
| Version | 1.0.0 |
| Last updated | YYYY-MM-DD |
| Upstream source | [URL to Figma / live site / inspiration] |
| CSS framework | Tailwind v4 \| Tailwind v3 \| vanilla \| CSS Modules |
| Component library | ShadCN \| MUI \| Radix Themes \| Radix Primitives \| Geist \| none |
| Theme modes | light \| dark \| both |
| Skill compatibility | awesome-design-md v1+ |

---

## 1. Visual Theme & Atmosphere

[Describe the mood. Dark-mode-first? Editorial? Dense data? Playful? Use
concrete observations: what's the background luminance? Where does chromatic
color appear? What's the type personality? 2–4 paragraphs. This is read by
humans as well as AI.]

**Key Characteristics:**
- [Bullet the 6–10 most distinctive traits]

---

## 2. Color Palette & Roles (CLOSED TOKEN LAYER)

> Every color used in components MUST reference a token below. The AI agent
> will refuse to emit literal hex/rgb/hsl values.

### 2.1 Primitive tokens (raw values)

```tokens color.neutral
- 50  (color): #fafafa
- 100 (color): #f5f5f5
- 200 (color): #e5e5e5
- 300 (color): #d4d4d4
- 400 (color): #a3a3a3
- 500 (color): #737373
- 600 (color): #525252
- 700 (color): #404040
- 800 (color): #262626
- 900 (color): #171717
- 950 (color): #0a0a0a
```

```tokens color.brand
- 50  (color): #eef2ff
- 100 (color): #e0e7ff
- 500 (color): #6366f1
- 600 (color): #4f46e5
- 700 (color): #4338ca
```

```tokens color.status
- success (color): #10b981
- warning (color): #f59e0b
- danger  (color): #ef4444
- info    (color): #3b82f6
```

### 2.2 Semantic tokens (role-based — what components reference)

| Token | Light value | Dark value | Role |
|---|---|---|---|
| `--color-bg` | `{color.neutral.50}` | `{color.neutral.950}` | Page background |
| `--color-surface` | `#ffffff` | `{color.neutral.900}` | Card / panel background |
| `--color-surface-raised` | `#ffffff` | `{color.neutral.800}` | Elevated surface |
| `--color-fg` | `{color.neutral.900}` | `{color.neutral.50}` | Primary text |
| `--color-fg-muted` | `{color.neutral.600}` | `{color.neutral.400}` | Secondary text |
| `--color-fg-subtle` | `{color.neutral.500}` | `{color.neutral.500}` | Tertiary / placeholder |
| `--color-border` | `{color.neutral.200}` | `{color.neutral.800}` | Default border |
| `--color-border-subtle` | `{color.neutral.100}` | `{color.neutral.900}` | Ultra-subtle divider |
| `--color-accent` | `{color.brand.600}` | `{color.brand.500}` | Primary CTA / interactive |
| `--color-accent-hover` | `{color.brand.700}` | `{color.brand.400}` | Hover state for accent |
| `--color-accent-fg` | `#ffffff` | `#ffffff` | Text ON accent bg |
| `--color-focus-ring` | `{color.brand.500}` | `{color.brand.400}` | Focus indicator |
| `--color-success` | `{color.status.success}` | `{color.status.success}` | Success state |
| `--color-warning` | `{color.status.warning}` | `{color.status.warning}` | Warning state |
| `--color-danger` | `{color.status.danger}` | `{color.status.danger}` | Error / destructive |

---

## 3. Typography Rules (CLOSED TOKEN LAYER)

### 3.1 Font families

```tokens font.family
- sans (fontFamily): ["Inter Variable", "system-ui", "sans-serif"]
- mono (fontFamily): ["JetBrains Mono", "ui-monospace", "Menlo"]
- display (fontFamily): ["Inter Variable", "system-ui", "sans-serif"]
```

### 3.2 Font weights (declared once, referenced by name)

```tokens font.weight
- regular  (fontWeight): 400
- medium   (fontWeight): 500
- semibold (fontWeight): 600
- bold     (fontWeight): 700
```

### 3.3 Fluid type scale (clamp-based, anchored 320–1440)

| Token | Formula | Min | Max | Weight | Line height | Tracking | Usage |
|---|---|---|---|---|---|---|---|
| `--text-xs`   | clamp(0.75, 0.70 + 0.25vw, 0.875)rem  | 12 | 14  | 400 | 1.50 | 0 | Meta, timestamps |
| `--text-sm`   | clamp(0.875, 0.80 + 0.30vw, 1)rem     | 14 | 16  | 400 | 1.50 | 0 | Secondary body |
| `--text-base` | clamp(1, 0.92 + 0.40vw, 1.125)rem     | 16 | 18  | 400 | 1.60 | 0 | Body |
| `--text-lg`   | clamp(1.125, 1.00 + 0.60vw, 1.375)rem | 18 | 22  | 500 | 1.50 | -0.01em | Lead |
| `--text-xl`   | clamp(1.375, 1.15 + 1.10vw, 1.75)rem  | 22 | 28  | 600 | 1.30 | -0.015em | H3 |
| `--text-2xl`  | clamp(1.75, 1.35 + 2.00vw, 2.5)rem    | 28 | 40  | 600 | 1.25 | -0.02em | H2 |
| `--text-3xl`  | clamp(2.25, 1.60 + 3.20vw, 3.75)rem   | 36 | 60  | 700 | 1.15 | -0.025em | H1 |
| `--text-4xl`  | clamp(3, 2.00 + 5.00vw, 5)rem         | 48 | 80  | 700 | 1.05 | -0.03em | Display |

### 3.4 Rules

- Never emit literal `font-size: 17px`. Use `text-lg` / `var(--text-lg)`.
- Never mix more than 2 typefaces on a surface.
- Negative tracking scales with size: 0 below 18px, -0.01em at 22px, down to -0.03em at 80px.
- Line height loosens for body (1.5–1.6), tightens for display (1.05–1.15).

---

## 4. Spacing, Radius, Shadow (CLOSED TOKEN LAYER)

### 4.1 Spacing scale (4px base unit)

```tokens space
- 0  (dimension): 0px
- 1  (dimension): 4px
- 2  (dimension): 8px
- 3  (dimension): 12px
- 4  (dimension): 16px
- 5  (dimension): 20px
- 6  (dimension): 24px
- 8  (dimension): 32px
- 10 (dimension): 40px
- 12 (dimension): 48px
- 16 (dimension): 64px
- 20 (dimension): 80px
- 24 (dimension): 96px
```

### 4.2 Radius scale

```tokens radius
- none (dimension): 0px
- sm   (dimension): 4px
- md   (dimension): 6px
- lg   (dimension): 8px
- xl   (dimension): 12px
- 2xl  (dimension): 16px
- full (dimension): 9999px
```

### 4.3 Shadow stack (elevation)

```tokens shadow
- xs (shadow): 0 1px 2px 0 rgb(0 0 0 / 0.05)
- sm (shadow): 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)
- md (shadow): 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)
- lg (shadow): 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)
- xl (shadow): 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)
- focus-ring (shadow): 0 0 0 3px var(--color-focus-ring)
```

---

## 5. Motion Tokens (CLOSED TOKEN LAYER)

### 5.1 Duration

```tokens duration
- instant (duration): 75ms
- fast    (duration): 150ms
- base    (duration): 200ms
- slow    (duration): 300ms
- slower  (duration): 500ms
```

### 5.2 Easing

```tokens ease
- out     (cubicBezier): [0.2, 0, 0, 1]
- in      (cubicBezier): [0.4, 0, 1, 1]
- in-out  (cubicBezier): [0.4, 0, 0.2, 1]
- spring  (cubicBezier): [0.175, 0.885, 0.32, 1.275]
```

### 5.3 Recipes

| Recipe | Properties | Duration | Easing | Use |
|---|---|---|---|---|
| Button press | `transform` | `instant` | `out` | `active:scale-[0.97]` |
| Hover lift | `transform, box-shadow` | `fast` | `out` | `hover:-translate-y-0.5` |
| Focus ring | `box-shadow` | `instant` | `out` | `:focus-visible` only |
| Toast enter | `transform, opacity` | `slow` | `out` | Slide+fade from y+20 |
| Modal enter | `transform, opacity` | `base` | `out` | Scale from 0.95 |
| Drawer enter | `transform` | `slow` | `out` | Slide from edge |
| Skeleton pulse | `opacity` | `2000ms` | `in-out` | Infinite data loading |
| Page transition | `opacity` | `slow` | `out` | View Transitions API |

### 5.4 Rules

- **Animate ONLY** `transform` and `opacity` (GPU-accelerated).
- NEVER animate `width`, `height`, `top`, `left`, `margin`, `padding` (layout thrashing).
- Default is static. Animate only with stated purpose (state change, enter/exit, affordance, hide latency).
- Always respect `@media (prefers-reduced-motion: reduce)` — replace translate/scale with opacity-only fade, or disable.
- Hover animations must complete in ≤ `fast`. Exit animations run 30% faster than enter (`fast` not `base`).

---

## 6. Component State Matrix

> Every interactive component MUST define all applicable states.
> A component that is missing a required state is INCOMPLETE and cannot ship.

### 6.1 Universal state tokens

For each state, declare the visual delta from `default`:
`bg` · `fg` · `border` · `shadow` · `outline` · `transform` · `opacity` · `cursor` · `transition`

### 6.2 Per-component requirements

| Component | Required states |
|---|---|
| Button | default, hover, focus-visible, active, disabled, loading |
| IconButton | default, hover, focus-visible, active, disabled |
| Input | default, hover, focus, filled, error, disabled, readonly |
| Textarea | default, hover, focus, filled, error, disabled, readonly |
| Checkbox | default, hover, checked, indeterminate, disabled, focus-visible |
| Radio | default, hover, checked, disabled, focus-visible |
| Switch | off, on, disabled, focus-visible |
| Select | closed, open, selected, disabled, focus-visible |
| Combobox | closed, open, filtered, no-results, disabled, focus-visible |
| Slider | default, hover, dragging, disabled, focus-visible |
| Tabs | default, hover, active, disabled, focus-visible |
| Link | default, hover, visited, focus-visible, active |
| Card (interactive) | default, hover, selected, focus-within, disabled |
| Menu item | default, hover, focused, selected, disabled |
| Tooltip | hidden, visible |
| Dialog | closed, opening, open, closing |
| Toast | enter, visible, exit |

### 6.3 Screen states (required for every data view)

`loading` (skeleton) · `empty` · `error` · `success` · `content`.
**Never ship a data view without all five.** Empty states are first-class deliverables (illustration + headline + body + primary CTA).

### 6.4 Focus ring standard (WCAG 2.2 AA)

```css
:focus-visible {
  outline: 3px solid var(--color-focus-ring);
  outline-offset: 2px;
  border-radius: inherit;
}
```

- **3px** outline thickness (≥ 2px required; 3px for safety margin)
- **2px** offset so the ring doesn't clip on corners
- **3:1 contrast** between focused and unfocused pixels
- Use `:focus-visible`, NOT `:focus` (prevents mouse-click outlines)

---

## 7. Layout & Responsive Behavior

### 7.1 Breakpoints

| Name | Min width | Target |
|---|---|---|
| `xs` | 0 | small phone |
| `sm` | 640px | large phone |
| `md` | 768px | tablet portrait |
| `lg` | 1024px | tablet landscape / small laptop |
| `xl` | 1280px | desktop |
| `2xl` | 1536px | wide desktop |

**Test at:** 320, 375, 768, 1024, 1440, 1920. No horizontal scroll at any width.

### 7.2 Container queries (component-level)

Reusable components should use container queries, not media queries:

```css
.card { container-type: inline-size; container-name: card; }
@container card (min-width: 32rem) {
  .card { grid-template-columns: 1fr 2fr; }
}
```

### 7.3 Responsive contracts per component

| Component | <640 | 640–1023 | ≥1024 |
|---|---|---|---|
| Nav | Hamburger drawer | Horizontal condensed | Full horizontal |
| Card grid | 1 col | 2 cols | 3–4 cols (auto-fit minmax 18rem) |
| Hero | Stacked | Stacked | Split 50/50 |
| Sidebar | Hidden / bottom sheet | Collapsible | Sticky 25% |
| Data table | Card list | Horizontal scroll | Full table |
| Form | 1 col | 1 col | 2 col (short fields only) |
| Footer | Stacked accordion | 2 col | 4 col subgrid |

### 7.4 Rules

- `min-height: 44px; min-width: 44px` on all interactive elements (WCAG 2.2 + Apple HIG)
- 8px minimum gap between adjacent touch targets
- Use `dvh`/`svh`/`lvh` instead of `vh` for mobile
- Use `env(safe-area-inset-*)` with `viewport-fit=cover`
- Use `aspect-ratio` + `max-width: 100%` for responsive media
- Pass 200% zoom without loss of content (WCAG 1.4.10 reflow)

---

## 8. Component Stylings

> For each component, define variants, sizes, and states using tokens only.

### 8.1 Button

**Variants:** `primary`, `secondary`, `ghost`, `danger`, `link`
**Sizes:** `sm` (32px), `md` (40px), `lg` (48px)

| Variant | bg | fg | border | hover bg | disabled opacity |
|---|---|---|---|---|---|
| primary | `--color-accent` | `--color-accent-fg` | none | `--color-accent-hover` | 0.5 |
| secondary | `--color-surface` | `--color-fg` | `--color-border` | `--color-surface-raised` | 0.5 |
| ghost | transparent | `--color-fg` | none | `--color-surface-raised` | 0.5 |
| danger | `--color-danger` | `#fff` | none | (darker danger) | 0.5 |
| link | transparent | `--color-accent` | none | underline | 0.5 |

**All variants:**
- `border-radius: var(--radius-md)`
- `font-weight: var(--font-weight-medium)`
- `transition: all var(--duration-fast) var(--ease-out)`
- `:active { transform: scale(0.97); }`
- `:focus-visible { box-shadow: var(--shadow-focus-ring); }`
- Loading state: spinner replaces label, width locked, `aria-busy="true"`
- Min size: 44×44

### 8.2 Input

```
bg: var(--color-surface)
fg: var(--color-fg)
border: 1px solid var(--color-border)
border-radius: var(--radius-md)
padding: var(--space-2) var(--space-3)
min-height: 44px
transition: border-color var(--duration-fast), box-shadow var(--duration-fast)

:hover    { border-color: var(--color-fg-subtle) }
:focus    { border-color: var(--color-accent); box-shadow: var(--shadow-focus-ring) }
[aria-invalid=true] { border-color: var(--color-danger) }
:disabled { opacity: 0.5; cursor: not-allowed }
[readonly]{ background: var(--color-surface-raised) }
```

### 8.3 Card

```
bg: var(--color-surface)
border: 1px solid var(--color-border)
border-radius: var(--radius-lg)
padding: var(--space-6)
shadow: var(--shadow-sm)

:hover (if interactive) {
  shadow: var(--shadow-md);
  transform: translateY(-2px);
  transition: all var(--duration-fast) var(--ease-out)
}
```

### 8.4 [Add more components as needed]

---

## 9. Do's and Don'ts

### Do
- Reference tokens for EVERY value in component code
- Use `:focus-visible` for focus rings
- Respect `prefers-reduced-motion`
- Test at 320 / 375 / 768 / 1024 / 1440 / 1920
- Define all required states from section 6.2 before shipping
- Extract sub-components when a file exceeds 300 LOC
- Use container queries for reusable components
- Use `dvh`/`svh`/`lvh` for full-height mobile sections

### Don't
- Don't emit literal `#hex`, `rgb()`, `hsl()`, or unscaled `px` in component code
- Don't animate `width`, `height`, `top`, `left`, `margin`, `padding`
- Don't use `outline: none` without a replacement of equal or greater visibility
- Don't skip hover / focus-visible / disabled states
- Don't exceed 300 LOC per component file (hard stop at 500)
- Don't drop shadows for elevation on dark surfaces — use background luminance stepping
- Don't use `:focus` — always `:focus-visible`
- Don't use `vh` on mobile — use `dvh`

---

## 10. Agent Prompt Guide

### Quick reference
- Surface: `var(--color-surface)` | Text: `var(--color-fg)` | Accent: `var(--color-accent)`
- Space: `var(--space-*)` (4px base) | Radius: `var(--radius-md)` default
- Duration: `var(--duration-fast)` | Easing: `var(--ease-out)`
- Focus: `:focus-visible { outline: 3px solid var(--color-focus-ring); outline-offset: 2px }`

### Example prompts (reuse these patterns)

**Create a Button:**
> Build a `Button` component with variants `primary | secondary | ghost | danger`, sizes `sm | md | lg`. Use only tokens from DESIGN.md. Include default, hover, focus-visible, active, disabled, and loading states. Loading state replaces label with a spinner and locks width. Min 44×44. `:focus-visible` only. Transition: `all var(--duration-fast) var(--ease-out)`. `:active { transform: scale(0.97) }`. Max 200 LOC.

**Build a Card:**
> Card on `var(--color-surface)`, `1px solid var(--color-border)`, `var(--radius-lg)`, `var(--space-6)` padding, `var(--shadow-sm)`. Interactive variant: `hover:shadow-md hover:-translate-y-0.5 transition-all duration-fast`. Use container queries for layout breakpoints, not media queries. Max 150 LOC.

**Recreate a screenshot:**
> I'm pasting a screenshot. Follow the 7-pass extraction loop from `references/screenshot-to-code-workflow.md`. Extract tokens, reconcile against this DESIGN.md, propose a diff for any NEW tokens (do not silently add them), generate the code using ONLY reconciled tokens, then self-score against the reference. Iterate until score ≥95.

### Iteration rules

1. ALWAYS reference a token; never a literal value.
2. Every interactive element needs hover, focus-visible, active, disabled at minimum.
3. Default is static; animate only with purpose (and always with `prefers-reduced-motion` guard).
4. Extract when a file approaches 300 LOC.
5. Test every layout at the 6 reference widths.
6. Run `scripts/quality-score.sh` before declaring done.
