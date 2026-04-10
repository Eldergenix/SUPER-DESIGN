# Design System: [PROJECT NAME]

> **This file is the closed token layer.** Every value in component code
> MUST reference a token defined here. The awesome-design-md skill's
> PostToolUse hooks will reject literals (`#hex`, `rgb()`, `hsl()`,
> unscaled `px`, inline color styles) in component files.
>
> **New tokens are added by proposal only.** When a component needs a value
> that doesn't exist here, emit a diff patch to this file and wait for
> approval before using it.

## 0. Meta

```yaml
version: 1.0.0
last_updated: YYYY-MM-DD
upstream_source: <url>
schema: https://github.com/VoltAgent/awesome-design-md/schema/v1
framework:
  css: tailwind-v4        # tailwind-v4 | tailwind-v3 | vanilla | css-modules
  component_library: none # shadcn | mui | radix-themes | radix-primitives | geist-ui | geist-font | none
theme_modes: [light, dark]
dark_mode_strategy: class-with-system-fallback
  # class — .dark on <html>, user toggle, persisted to localStorage
  # media — prefers-color-scheme only, no toggle
  # class-with-system-fallback — .dark class OR system preference (recommended)
i18n:
  rtl_support: true
  logical_properties: true  # use margin-inline, padding-block, etc.
```

## 1. Brand Narrative & Philosophy

[3–5 sentences on mood, personality, and tone. This is the ONE place where
prose beats structure. Short, evocative, specific. Read by humans and AI.]

**Principles (non-negotiable):**
1. Tokens over literals. Semantic over primitive. Components reference `--color-fg`, never `--color-neutral-900`.
2. Clarity over cleverness. A label beats an icon. A button beats an ambiguous affordance.
3. Motion is communication, not decoration. Default is static.
4. Accessibility is a gate, not a feature. WCAG 2.2 AA minimum.
5. Responsive by default. Container-queried where reusable.

## 2. Color System

Colors live in **three layers**: primitive (raw values), semantic (role aliases), component (per-component references). **Component code references ONLY the semantic layer.**

### 2.1 Primitive palette (raw values — OKLCH for wide gamut, with sRGB hex fallback)

```tokens color.neutral
- 50  (color): oklch(98.5% 0 0)   # fallback: #fafafa
- 100 (color): oklch(96.8% 0 0)   # fallback: #f5f5f5
- 200 (color): oklch(92.2% 0 0)   # fallback: #e5e5e5
- 300 (color): oklch(86.8% 0 0)   # fallback: #d4d4d4
- 400 (color): oklch(70.4% 0 0)   # fallback: #a3a3a3
- 500 (color): oklch(55.6% 0 0)   # fallback: #737373
- 600 (color): oklch(43.9% 0 0)   # fallback: #525252
- 700 (color): oklch(37.1% 0 0)   # fallback: #404040
- 800 (color): oklch(26.9% 0 0)   # fallback: #262626
- 900 (color): oklch(20.5% 0 0)   # fallback: #171717
- 950 (color): oklch(14.5% 0 0)   # fallback: #0a0a0a
```

```tokens color.brand
- 50  (color): oklch(97.0% 0.014 256)
- 100 (color): oklch(93.2% 0.032 256)
- 200 (color): oklch(87.0% 0.061 256)
- 300 (color): oklch(79.2% 0.099 256)
- 400 (color): oklch(70.7% 0.146 256)
- 500 (color): oklch(62.3% 0.188 260)
- 600 (color): oklch(54.6% 0.215 263)
- 700 (color): oklch(48.8% 0.215 264)
- 800 (color): oklch(42.4% 0.199 265)
- 900 (color): oklch(37.9% 0.146 266)
```

```tokens color.status
- success-500 (color): oklch(72.3% 0.219 149)
- warning-500 (color): oklch(79.5% 0.184 86)
- danger-500  (color): oklch(63.7% 0.237 25)
- info-500    (color): oklch(70.4% 0.168 244)
```

### 2.2 Semantic layer (roles — THIS is what components reference)

| Token | Light | Dark | Role | Required contrast |
|---|---|---|---|---|
| `--color-bg` | `{color.neutral.50}` | `{color.neutral.950}` | Page background | — |
| `--color-bg-subtle` | `{color.neutral.100}` | `{color.neutral.900}` | Muted section bg | — |
| `--color-surface` | `#ffffff` | `{color.neutral.900}` | Card / panel | — |
| `--color-surface-raised` | `{color.neutral.50}` | `{color.neutral.800}` | Elevated surface | — |
| `--color-surface-overlay` | `rgba(255,255,255,0.9)` | `rgba(10,10,10,0.9)` | Modal/popover bg | — |
| `--color-fg` | `{color.neutral.900}` | `{color.neutral.50}` | Primary text | 7:1 vs bg (AAA) |
| `--color-fg-muted` | `{color.neutral.600}` | `{color.neutral.400}` | Secondary text | 4.5:1 vs bg (AA) |
| `--color-fg-subtle` | `{color.neutral.500}` | `{color.neutral.500}` | Placeholder, meta | 3:1 vs bg (AA-large) |
| `--color-fg-on-accent` | `#ffffff` | `#ffffff` | Text on accent | 4.5:1 vs accent |
| `--color-border` | `{color.neutral.300}` | `{color.neutral.700}` | Default border (decorative — pair with elevation) | advisory 1.5:1 |
| `--color-border-subtle` | `{color.neutral.100}` | `{color.neutral.800}` | Ultra-subtle divider (decorative only) | — |
| `--color-border-strong` | `{color.neutral.500}` | `{color.neutral.400}` | Emphasized border (sole boundary — meets 3:1) | 3:1 vs adjacent |
| `--color-accent` | `{color.brand.600}` | `{color.brand.600}` | Primary CTA / interactive | 4.5:1 vs fg-on-accent |
| `--color-accent-hover` | `{color.brand.700}` | `{color.brand.500}` | Hover on accent | — |
| `--color-accent-subtle` | `{color.brand.50}` | `{color.brand.900}` | Accent-tinted surface | — |
| `--color-focus-ring` | `{color.brand.500}` | `{color.brand.400}` | Focus indicator | 3:1 vs adjacent |
| `--color-success` | `{color.status.success-500}` | `{color.status.success-500}` | Success state | 4.5:1 vs white |
| `--color-warning` | `{color.status.warning-500}` | `{color.status.warning-500}` | Warning state | 4.5:1 vs black |
| `--color-danger` | `{color.status.danger-500}` | `{color.status.danger-500}` | Error / destructive | 4.5:1 vs white |
| `--color-info` | `{color.status.info-500}` | `{color.status.info-500}` | Info state | 4.5:1 vs white |

### 2.3 Forced-colors mode (Windows High Contrast)

Components MUST declare `forced-colors` adjustments on interactive surfaces:

```css
@media (forced-colors: active) {
  .button {
    border: 1px solid ButtonText;
    forced-color-adjust: none;
  }
  .button:focus-visible {
    outline: 3px solid Highlight;
    outline-offset: 2px;
  }
}
```

Tailwind equivalents: `forced-colors:border forced-colors:border-[ButtonText]`.

### 2.4 High-contrast preference

```css
@media (prefers-contrast: more) {
  :root {
    --color-border: var(--color-border-strong);
    --color-fg-muted: var(--color-fg);
  }
}
```

## 3. Typography

### 3.1 Font families

```tokens font.family
- sans    (fontFamily): ["Inter Variable", "system-ui", "sans-serif"]
- display (fontFamily): ["Inter Variable", "system-ui", "sans-serif"]
- mono    (fontFamily): ["JetBrains Mono", "ui-monospace", "Menlo"]
```

### 3.2 Font loading strategy (CLS prevention)

```html
<link rel="preconnect" href="https://rsms.me" crossorigin>
<link rel="preload" href="/fonts/InterVariable.woff2" as="font" type="font/woff2" crossorigin>
```

```css
@font-face {
  font-family: "Inter Variable";
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;                    /* or optional for stricter CLS */
  src: url("/fonts/InterVariable.woff2") format("woff2");
  /* Fallback metrics — keep layout stable during font swap */
  ascent-override: 90%;
  descent-override: 22%;
  line-gap-override: 0%;
  size-adjust: 107%;
}
```

**Use `font-display: optional`** on brand-critical display text to prevent FOUT entirely. **Use `font-display: swap`** on body text to avoid invisible text. Never `block`.

### 3.3 Font weights (full scale including the signature weight)

```tokens font.weight
- thin      (fontWeight): 100
- light     (fontWeight): 300
- regular   (fontWeight): 400
- signature (fontWeight): 510   # between 500 and 600 — Linear-style UI emphasis
- medium    (fontWeight): 500
- semibold  (fontWeight): 600
- bold      (fontWeight): 700
```

### 3.4 Fluid type scale (clamp + logical line-height tokens)

| Token | Clamp | Min | Max | Weight token | `--leading-*` | `--tracking-*` |
|---|---|---|---|---|---|---|
| `--text-xs`   | `clamp(0.75rem,  0.70rem + 0.25vw, 0.875rem)` | 12 | 14  | regular  | `tight` (1.4)    | `normal` |
| `--text-sm`   | `clamp(0.875rem, 0.80rem + 0.30vw, 1rem)`     | 14 | 16  | regular  | `normal` (1.5)   | `normal` |
| `--text-base` | `clamp(1rem,     0.92rem + 0.40vw, 1.125rem)` | 16 | 18  | regular  | `relaxed` (1.6)  | `normal` |
| `--text-lg`   | `clamp(1.125rem, 1.00rem + 0.60vw, 1.375rem)` | 18 | 22  | signature| `snug` (1.5)     | `tight-1` |
| `--text-xl`   | `clamp(1.375rem, 1.15rem + 1.10vw, 1.75rem)`  | 22 | 28  | semibold | `snug` (1.3)     | `tight-2` |
| `--text-2xl`  | `clamp(1.75rem,  1.35rem + 2.00vw, 2.5rem)`   | 28 | 40  | semibold | `tight` (1.25)   | `tight-3` |
| `--text-3xl`  | `clamp(2.25rem,  1.60rem + 3.20vw, 3.75rem)`  | 36 | 60  | bold     | `tighter` (1.15) | `tight-4` |
| `--text-4xl`  | `clamp(3rem,     2.00rem + 5.00vw, 5rem)`     | 48 | 80  | bold     | `tightest` (1.05)| `tight-5` |

```tokens leading
- tightest (lineHeight): 1.05
- tighter  (lineHeight): 1.15
- tight    (lineHeight): 1.25
- snug     (lineHeight): 1.33
- normal   (lineHeight): 1.50
- relaxed  (lineHeight): 1.60
- loose    (lineHeight): 1.80
```

```tokens tracking
- normal   (letterSpacing): 0
- tight-1  (letterSpacing): -0.01em
- tight-2  (letterSpacing): -0.015em
- tight-3  (letterSpacing): -0.02em
- tight-4  (letterSpacing): -0.025em
- tight-5  (letterSpacing): -0.03em
- wide-1   (letterSpacing): 0.025em
- wide-2   (letterSpacing): 0.05em
```

## 4. Spacing (inset / stack / inline separation)

Adobe Spectrum / Carbon style: spacing tokens are named by **direction of application**, not by generic scale. Components use the role-specific alias, not the raw number.

### 4.1 Base scale (4px grid)

```tokens space
- 0  (dimension): 0
- px (dimension): 1px
- 0.5(dimension): 2px
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

### 4.2 Role aliases

```tokens inset  # padding inside containers
- xs (dimension): {space.2}   # 8px — tight buttons, pills
- sm (dimension): {space.3}   # 12px — compact cards
- md (dimension): {space.4}   # 16px — standard
- lg (dimension): {space.6}   # 24px — roomy cards
- xl (dimension): {space.8}   # 32px — hero sections
```

```tokens stack  # vertical gap between siblings
- xs (dimension): {space.1}   # 4px
- sm (dimension): {space.2}   # 8px
- md (dimension): {space.4}   # 16px
- lg (dimension): {space.6}   # 24px
- xl (dimension): {space.10}  # 40px
- 2xl(dimension): {space.16}  # 64px — section breaks
```

```tokens inline  # horizontal gap in flex/grid rows
- xs (dimension): {space.1}
- sm (dimension): {space.2}
- md (dimension): {space.3}
- lg (dimension): {space.4}
- xl (dimension): {space.6}
```

**Rule:** components use `padding: var(--inset-md)`, `gap: var(--stack-md)`, NOT `padding: var(--space-4)`. This makes design refactors refactor by intent, not by literal.

### 4.3 Use logical properties for i18n/RTL

```css
/* ❌ Wrong */
.card { padding-left: var(--inset-md); margin-right: var(--stack-sm); }

/* ✓ Right — flips automatically under dir="rtl" */
.card { padding-inline-start: var(--inset-md); margin-inline-end: var(--stack-sm); }
```

## 5. Radius & Shape

```tokens radius
- none (dimension): 0
- xs   (dimension): 2px
- sm   (dimension): 4px
- md   (dimension): 6px
- lg   (dimension): 8px
- xl   (dimension): 12px
- 2xl  (dimension): 16px
- 3xl  (dimension): 24px
- full (dimension): 9999px
```

## 6. Elevation & Shadow

```tokens shadow
- xs (shadow): "0 1px 2px 0 rgb(0 0 0 / 0.05)"
- sm (shadow): "0 1px 3px 0 rgb(0 0 0 / 0.10), 0 1px 2px -1px rgb(0 0 0 / 0.10)"
- md (shadow): "0 4px 6px -1px rgb(0 0 0 / 0.10), 0 2px 4px -2px rgb(0 0 0 / 0.10)"
- lg (shadow): "0 10px 15px -3px rgb(0 0 0 / 0.10), 0 4px 6px -4px rgb(0 0 0 / 0.10)"
- xl (shadow): "0 20px 25px -5px rgb(0 0 0 / 0.10), 0 8px 10px -6px rgb(0 0 0 / 0.10)"
- inner (shadow): "inset 0 2px 4px 0 rgb(0 0 0 / 0.05)"
```

### Focus ring (double-layer for 3:1 contrast on any background)

```css
.focus-ring {
  box-shadow:
    0 0 0 2px var(--color-bg),           /* inner offset to background */
    0 0 0 5px var(--color-focus-ring);   /* outer ring */
}
```

The inner `--color-bg` ring creates separation from the element's own background, guaranteeing 3:1 regardless of what's behind. This is the Stripe/Linear/Vercel standard.

## 7. Motion

### 7.1 Duration & easing

```tokens duration
- instant (duration): 75ms
- fast    (duration): 150ms
- base    (duration): 200ms
- slow    (duration): 300ms
- slower  (duration): 500ms
```

```tokens ease
- out     (cubicBezier): [0.2, 0, 0, 1]
- in      (cubicBezier): [0.4, 0, 1, 1]
- in-out  (cubicBezier): [0.4, 0, 0.2, 1]
- spring  (cubicBezier): [0.175, 0.885, 0.32, 1.275]
- ios     (cubicBezier): [0.25, 0.1, 0.25, 1]
```

### 7.2 Intent delays

```tokens delay
- tooltip-show  (duration): 500ms
- tooltip-hide  (duration): 0ms
- hover-intent  (duration): 100ms
```

### 7.3 Rules

- Animate `transform` and `opacity` ONLY. Never `width`/`height`/`top`/`left`/`margin`/`padding`.
- Default is static. Animate only with stated purpose.
- Exit is 30% faster than enter.
- Global `prefers-reduced-motion` guard (MANDATORY):

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  .fade-up, .slide-in, .scale-in { transform: none; }
}
```

## 8. Component State Matrix

Every interactive component MUST define all applicable states. See `references/state-matrix.md` and the machine-readable `STATE_MATRIX.yaml` for the enforceable schema.

### 8.1 Button (concrete example)

```yaml
component: Button
required_states:
  - default
  - hover
  - focus-visible
  - active
  - disabled
  - loading
tokens:
  default:
    bg: var(--color-accent)
    fg: var(--color-fg-on-accent)
    shadow: none
  hover:
    bg: var(--color-accent-hover)
    transition: background-color var(--duration-fast) var(--ease-out)
  focus-visible:
    box-shadow: 0 0 0 2px var(--color-bg), 0 0 0 5px var(--color-focus-ring)
    outline: none
  active:
    transform: scale(0.98)
    transition: transform var(--duration-instant) var(--ease-out)
  disabled:
    opacity: 0.5
    cursor: not-allowed
    pointer-events: none
  loading:
    aria-busy: true
    opacity: 0.7
    cursor: wait
min_size: { width: 44px, height: 44px }  # WCAG 2.2 SC 2.5.8
forced_colors:
  border: 1px solid ButtonText
  focus-visible:
    outline: 3px solid Highlight
```

### 8.2 Screen states

Required for every data view: `loading` (skeleton) · `empty` · `error` · `success` · `content`. Never ship a data view without all five.

### 8.3 Skeleton colors (derived from surface, not hardcoded)

```css
.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-surface) 0%,
    var(--color-surface-raised) 50%,
    var(--color-surface) 100%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 2s ease-in-out infinite;
}
@keyframes skeleton-shimmer {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
@media (prefers-reduced-motion: reduce) {
  .skeleton { animation: none; background: var(--color-surface-raised); }
}
```

This automatically re-themes with dark mode — the shimmer is always the step above the base surface.

## 9. Layout & Responsive

### 9.1 Breakpoints

| Name | Min width | Target |
|---|---|---|
| `xs` | 0 | small phone |
| `sm` | 640px | large phone |
| `md` | 768px | tablet portrait |
| `lg` | 1024px | tablet landscape / small laptop |
| `xl` | 1280px | desktop |
| `2xl` | 1536px | wide desktop |

**Test at:** 320, 375, 768, 1024, 1440, 1920. No horizontal scroll at any width.

### 9.2 Rules

- Reusable components use container queries (`@container`), not viewport media queries.
- Page shells use viewport media queries.
- Touch targets: min 44×44 CSS px, 8px gap.
- Use `dvh`/`svh`/`lvh` instead of `vh`.
- Use `env(safe-area-inset-*)` with `viewport-fit=cover`.
- Images: `max-width: 100%; height: auto;` or `aspect-ratio`.
- Pass 200% zoom (WCAG 1.4.10 reflow).

## 10. Agent Prompt Guide

### 10.1 Generating a component (the correct prompt pattern)

> "Create `<Component>` using tokens from DESIGN.md sections 2–8. Variants: [list]. Sizes: [list]. States: default, hover, focus-visible (double-ring), active (scale 0.98), disabled (opacity 0.5), loading (aria-busy, opacity 0.7). Min 44×44. Use `:focus-visible` only. `forced-colors:` fallback. Transition `transform` and `opacity` only, `var(--duration-fast) var(--ease-out)`. Max 200 LOC. Test with `scripts/test.sh`."

### 10.2 Starting from a screenshot

> "Run the 7-pass extraction loop from `references/screenshot-to-code-workflow.md`. Crop dense regions with `scripts/crop-region.sh`. Reconcile tokens against this DESIGN.md at pass 5. Do not invent tokens — propose a diff and wait for approval. Verify at pass 7 with `scripts/visual-diff.mjs`, target score ≥ 95."

### 10.3 Iterating on feedback

> "Read the user's note. Identify which tokens or states are implicated. Change ONLY those. Re-run `scripts/quality-score.sh`. If the score drops, explain why and propose an alternative."
