# Design System: Example Linear Dashboard

> **This file is the closed token layer.** Every color, size, and spacing
> value in component code MUST reference a token defined here. Component
> code must NOT contain literal `#hex`, `rgb()`, `hsl()`, or unscaled `px`
> values. New tokens are added by proposal (diff to this file).
>
> **Source**: Translated from `super-design-md/linear.app/DESIGN.md` in the
> Super Design repo into the skill's structured token schema so that
> `generate-theme.mjs` can emit a Tailwind v4 theme from it. The brand
> extraction doc has the human-readable narrative; this file has the
> machine-readable tokens. Both should agree.

## 0. Meta

```yaml
version: 1.0.0
last_updated: 2026-04-10
upstream_source: https://linear.app/
schema: https://github.com/Eldergenix/SUPER-DESIGN/schema/v1
framework:
  css: tailwind-v4
  component_library: none
theme_modes: [dark]
dark_mode_strategy: class
  # This example ships dark-only — Linear's native medium. Light-mode
  # values are still declared below so the theme is theoretically
  # completable, but the app forces .dark on <html>.
i18n:
  rtl_support: true
  logical_properties: true
```

## 1. Brand Narrative & Philosophy

Linear is dark-mode-native: near-black canvas where content emerges from darkness like starlight. Information density is managed through gradations of white opacity, not color variation. Typography is Inter Variable with OpenType features `"cv01", "ss03"` globally enabled, using a three-weight system (400 read, 510 emphasis, 590 strong). A single chromatic accent — indigo-violet `#5e6ad2` / `#7170ff` — punctuates an otherwise achromatic palette. Borders are whisper-thin semi-transparent white, never solid dark colors on dark.

**Principles (non-negotiable):**
1. Tokens over literals. Components reference `--color-fg`, never `#f7f8f8`.
2. Luminance stacking for elevation — deeper surfaces are darker, elevated surfaces have slightly higher white opacity. Never drop shadows on dark.
3. OpenType is identity — `"cv01", "ss03"` are not decorative. Without them, it's generic Inter, not Linear's Inter.
4. Brand indigo is reserved — CTAs, active states, selection only. No decorative use.
5. Accessibility is a gate. WCAG 2.2 AA contrast, visible `:focus-visible`, forced-colors fallback.

## 2. Color System

### 2.1 Primitive palette

```tokens color.neutral
- 50  (color): #f7f8f8
- 100 (color): #e2e4e7
- 200 (color): #d0d6e0
- 300 (color): #8a8f98
- 400 (color): #62666d
- 500 (color): #3e3e44
- 600 (color): #34343a
- 700 (color): #28282c
- 800 (color): #23252a
- 900 (color): #191a1b
- 950 (color): #0f1011
- 975 (color): #08090a
- 999 (color): #010102
```

```tokens color.brand
- 400 (color): #828fff
- 500 (color): #7170ff
- 600 (color): #5e6ad2
- 700 (color): #4c57b0
- 800 (color): #3b4585
- 900 (color): #7a7fad
```

```tokens color.status
- success-500 (color): #10b981
- success-600 (color): #27a644
- warning-500 (color): #f2c94c
- danger-500  (color): #eb5757
- info-500    (color): #7170ff
```

### 2.2 Semantic color table

The semantic layer is what component code references. Dark values are the primary target; light values exist for completeness but the dashboard ships dark-only.

| Token | Light | Dark |
|---|---|---|
| `--color-bg` | #ffffff | {color.neutral.975} |
| `--color-bg-panel` | #f7f8f8 | {color.neutral.950} |
| `--color-surface` | #ffffff | {color.neutral.900} |
| `--color-surface-raised` | #f3f4f5 | {color.neutral.700} |
| `--color-surface-hover` | #f5f6f7 | {color.neutral.600} |
| `--color-fg` | {color.neutral.975} | {color.neutral.50} |
| `--color-fg-muted` | {color.neutral.400} | {color.neutral.200} |
| `--color-fg-subtle` | {color.neutral.300} | {color.neutral.300} |
| `--color-fg-faint` | {color.neutral.400} | {color.neutral.400} |
| `--color-border` | {color.neutral.200} | {color.neutral.800} |
| `--color-border-strong` | {color.neutral.300} | {color.neutral.700} |
| `--color-border-subtle` | {color.neutral.100} | {color.neutral.900} |
| `--color-accent` | {color.brand.600} | {color.brand.500} |
| `--color-accent-hover` | {color.brand.500} | {color.brand.400} |
| `--color-accent-muted` | {color.brand.900} | {color.brand.900} |
| `--color-ring` | {color.brand.500} | {color.brand.400} |
| `--color-success` | {color.status.success-500} | {color.status.success-500} |
| `--color-warning` | {color.status.warning-500} | {color.status.warning-500} |
| `--color-danger` | {color.status.danger-500} | {color.status.danger-500} |

## 3. Typography

```tokens font.family
- sans (string): "Inter Variable", "SF Pro Display", -apple-system, system-ui, Segoe UI, Roboto, "Helvetica Neue", sans-serif
- mono (string): "Berkeley Mono", ui-monospace, "SF Mono", Menlo, monospace
```

```tokens font.weight
- light    (number): 300
- regular  (number): 400
- medium   (number): 510
- semibold (number): 590
```

```tokens font.feature
- default (string): "cv01", "ss03"
```

### Hierarchy

| Role | Family | Size | Weight | Line Height | Letter Spacing |
|---|---|---|---|---|---|
| Display | sans | 48px (3.00rem) | 510 | 1.00 | -1.056px |
| H1 | sans | 32px (2.00rem) | 400 | 1.13 | -0.704px |
| H2 | sans | 24px (1.50rem) | 400 | 1.33 | -0.288px |
| H3 | sans | 20px (1.25rem) | 590 | 1.33 | -0.24px |
| Body Large | sans | 18px (1.13rem) | 400 | 1.60 | -0.165px |
| Body | sans | 15px (0.94rem) | 400 | 1.50 | -0.165px |
| Body Medium | sans | 15px (0.94rem) | 510 | 1.50 | -0.165px |
| Label | sans | 13px (0.81rem) | 510 | 1.40 | -0.13px |
| Caption | sans | 12px (0.75rem) | 510 | 1.40 | normal |
| Micro | sans | 11px (0.69rem) | 510 | 1.40 | normal |

## 4. Spacing

Base unit: 4px. Linear's optical scale snaps to 4/8 but uses 7/11 for micro-adjustments.

```tokens inset
- xs (dimension): 4px
- sm (dimension): 8px
- md (dimension): 12px
- lg (dimension): 16px
- xl (dimension): 24px
- 2xl (dimension): 32px
```

```tokens stack
- xs (dimension): 2px
- sm (dimension): 4px
- md (dimension): 8px
- lg (dimension): 12px
- xl (dimension): 16px
- 2xl (dimension): 24px
- 3xl (dimension): 32px
```

```tokens inline
- xs (dimension): 2px
- sm (dimension): 4px
- md (dimension): 6px
- lg (dimension): 8px
- xl (dimension): 12px
```

## 5. Radius

```tokens radius
- micro      (dimension): 2px
- sm         (dimension): 4px
- md         (dimension): 6px
- lg         (dimension): 8px
- xl         (dimension): 12px
- 2xl        (dimension): 22px
- pill       (dimension): 9999px
- full       (dimension): 50%
```

## 6. Shadow / Elevation

```tokens shadow
- none  (shadow): none
- subtle (shadow): 0 1.2px 0 0 rgba(0, 0, 0, 0.03)
- ring  (shadow): 0 0 0 1px rgba(0, 0, 0, 0.2)
- card  (shadow): 0 0 0 1px rgba(255, 255, 255, 0.05)
- popover (shadow): 0 8px 24px -8px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.08)
- focus (shadow): 0 0 0 2px var(--color-bg), 0 0 0 4px var(--color-ring)
```

## 7. Motion

```tokens duration
- instant (duration): 0ms
- fast (duration): 80ms
- base (duration): 150ms
- slow (duration): 240ms
```

```tokens ease
- standard (cubic-bezier): [0.2, 0, 0, 1]
- emphasized (cubic-bezier): [0.3, 0, 0.1, 1]
```

## 8. Component Tokens (informative)

Not consumed by `generate-theme.mjs` — listed so component authors know the intended recipes.

- **Ghost button**: bg `rgba(255,255,255,0.02)` (encoded as `--color-surface`), text `--color-fg-muted`, border `--color-border`, radius `--radius-md`, padding `--inset-sm --inset-md`.
- **Pill (selected)**: bg `--color-surface-raised`, text `--color-fg`, radius `--radius-pill`, padding `0 --inset-md`, height 28px.
- **Sidebar nav item**: base text `--color-fg-muted`, hover bg `--color-surface-hover`, selected bg `--color-surface-raised` + text `--color-fg`, radius `--radius-md`, padding `--inset-xs --inset-sm`, gap `--inline-lg`.
- **Table row**: row height 44px, border-bottom `--color-border-subtle`, hover bg `--color-surface`, gap `--inline-xl`.
- **Status chip**: text `--color-fg-subtle`, icon color `--color-fg-faint`, gap `--inline-md`, caption typography.

## 9. Accessibility

- **Contrast**: all text/bg pairings in the semantic table must pass WCAG 2.2 AA (4.5:1 body, 3:1 large). Run `contrast-check.mjs` against this file.
- **Focus**: `:focus-visible` rings use `--shadow-focus` — double-layer with bg gap for visibility on any surface. `:focus` without `:focus-visible` is forbidden by the skill's hooks.
- **Reduced motion**: all transitions respect `prefers-reduced-motion: reduce` (set globally in generated CSS).
- **Forced colors**: semantic `--color-border` falls back to `CanvasText` under `prefers-contrast: more`; interactive surfaces declare `border: 1px solid transparent` so they remain visible in Windows High Contrast.

## 10. Iteration Guide (for agents)

1. Apply `font-feature-settings: "cv01", "ss03"` on the root element. Non-negotiable.
2. Use weight 510 (not 500) as the default emphasis weight.
3. Semantic tokens only in component code. Primitive tokens (`--color-neutral-950`) appear only in `@theme`.
4. Elevation = background luminance step, not shadow darkness. `--color-bg` (deepest) → `--color-bg-panel` → `--color-surface` → `--color-surface-raised`.
5. Brand indigo (`--color-accent`) appears only on interactive accents. If it's appearing decoratively, replace it with `--color-fg-muted` or `--color-border-strong`.
6. Borders are `--color-border` (translucent white, semantic). Never hand-write `rgba(255,255,255,0.08)` in a component.
