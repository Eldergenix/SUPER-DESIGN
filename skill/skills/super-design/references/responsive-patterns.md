# Responsive Patterns (2025-2026 best practices)

## Core decisions

**Grid vs Flexbox**
- Grid for 2D page skeletons (header/sidebar/main/footer, dashboards, card grids)
- Flexbox for 1D component internals (navbars, toolbars, button groups, form rows)
- Rule: **Grid for layout, Flexbox for flow**

**Container vs Media queries**
- Media queries for page-level layout and OS preferences
- Container queries (`@container`) for reusable components — a Card in a sidebar adapts to its container, not the viewport

**Subgrid** (97% support, safe) — use for aligning nested items to an outer grid.

**Content-first beats breakpoint-first.** Start narrow, let content drive breakpoints. Add a breakpoint only when the layout breaks.

## Breakpoints (Tailwind-aligned)

```css
--bp-sm:  640px;  /* large phone */
--bp-md:  768px;  /* tablet portrait */
--bp-lg:  1024px; /* tablet landscape / small laptop */
--bp-xl:  1280px; /* desktop */
--bp-2xl: 1536px; /* wide desktop */
```

**Test widths: 320, 375, 768, 1024, 1440, 1920.**

## Fluid type tokens (clamp-based)

Formula: `clamp(MIN, MIN + (MAX-MIN) * ((100vw - MINVW)/(MAXVW-MINVW)), MAX)`
Anchor viewports: 320px → 1440px.

```css
--text-xs:   clamp(0.75rem,  0.70rem + 0.25vw, 0.875rem);
--text-sm:   clamp(0.875rem, 0.80rem + 0.30vw, 1rem);
--text-base: clamp(1rem,     0.92rem + 0.40vw, 1.125rem);
--text-lg:   clamp(1.125rem, 1.00rem + 0.60vw, 1.375rem);
--text-xl:   clamp(1.375rem, 1.15rem + 1.10vw, 1.75rem);
--text-2xl:  clamp(1.75rem,  1.35rem + 2.00vw, 2.5rem);
--text-3xl:  clamp(2.25rem,  1.60rem + 3.20vw, 3.75rem);
--text-4xl:  clamp(3rem,     2.00rem + 5.00vw, 5rem);
```

## Container query patterns (reusable components)

```css
.card {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 32rem) {
  .card {
    grid-template-columns: 1fr 2fr;
  }
}

.media-object { container-type: inline-size; }
@container (min-width: 24rem) {
  .media-object { flex-direction: row; }
}
```

## Intrinsic grid primitives

```css
/* Auto-wrapping card grid, no breakpoint math needed */
.grid-auto {
  display: grid;
  gap: var(--space-4);
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 18rem), 1fr));
}

/* App shell with sidebar */
.grid-sidebar {
  display: grid;
  gap: var(--space-6);
  grid-template-columns: minmax(16rem, 25%) 1fr;
}
```

## Per-component responsive contracts

| Component | <640 | 640–1023 | ≥1024 |
|---|---|---|---|
| Nav | Hamburger drawer, vertical | Horizontal condensed | Full horizontal with mega-menu |
| Card grid | 1 col | 2 cols (container-driven) | 3–4 cols (auto-fit minmax 18rem) |
| Hero | Stacked, text above image | Stacked | Split 50/50, text left |
| Sidebar | Hidden / bottom sheet | Collapsible | Sticky 25% |
| Data table | Card list (stack) | Horizontal scroll | Full table |
| Form | 1 col, labels above | 1 col | 2 col grid for short fields |
| Footer | Stacked accordion | 2 col | 4 col subgrid |

## Touch targets (WCAG 2.2 SC 2.5.8)

- **Minimum:** 24×24 CSS px (AA)
- **Recommended:** 44×44 CSS px (Apple HIG, WCAG AAA 2.5.5)
- **Android:** 48×48 dp (Material)
- **Rule:** all interactive elements `min-height: 44px; min-width: 44px;` with `::before` hit-area expansion for visually smaller controls
- **Minimum 8px gap** between targets

## Safe-area insets (mobile web)

Requires `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`.

```css
body {
  padding:
    max(var(--space-4), env(safe-area-inset-top))
    max(var(--space-4), env(safe-area-inset-right))
    max(var(--space-4), env(safe-area-inset-bottom))
    max(var(--space-4), env(safe-area-inset-left));
}
```

## Mobile viewport units

Use `dvh` / `svh` / `lvh` instead of `vh`:
- `dvh` — dynamic viewport height (adjusts with browser UI)
- `svh` — smallest viewport height
- `lvh` — largest viewport height

## Self-validation checklist (AI agent runs before declaring done)

- [ ] Renders at 320, 375, 768, 1024, 1440, 1920 with no horizontal scroll
- [ ] No body text below 16px
- [ ] Fluid type tokens used (clamp) — not hardcoded px
- [ ] No fixed pixel widths on containers (max-width in ch/rem OK)
- [ ] All interactive targets ≥ 24×24, recommended 44×44, 8px spacing
- [ ] Nav collapses at < 768px, hamburger reachable one-handed
- [ ] Images use `max-width: 100%; height: auto;` or `aspect-ratio`
- [ ] Grids use `auto-fit minmax()` not hard-coded column counts
- [ ] Components use container queries, not viewport MQ, where reusable
- [ ] `viewport-fit=cover` + `env(safe-area-inset-*)` on edge-bleed UI
- [ ] `dvh` / `svh` used instead of `vh` for full-height sections
- [ ] Tested with 200% zoom (WCAG 1.4.10 reflow)
- [ ] Tested with `prefers-reduced-motion`, `prefers-color-scheme`
- [ ] Subgrid used for aligned nested components where applicable
