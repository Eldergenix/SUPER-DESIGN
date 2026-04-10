# Framework Adapter: Radix UI (Themes + Primitives)

## Detection

- **Radix Themes** (styled): `@radix-ui/themes` in `package.json`, import of `@radix-ui/themes/styles.css`
- **Radix Primitives** (headless): `@radix-ui/react-*` packages (e.g. `react-dialog`, `react-dropdown-menu`) — style with Tailwind/CSS yourself

## Strategy — Radix Themes

Wrap the app in `<Theme>` with props derived from DESIGN.md, then override Radix Themes' CSS variables in a stylesheet loaded AFTER `@radix-ui/themes/styles.css`.

## Template — Radix Themes setup

```tsx
// app/layout.tsx (Next.js) or root component
import "@radix-ui/themes/styles.css";
import "./theme-overrides.css";  // MUST load after Radix styles
import { Theme } from "@radix-ui/themes";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Theme
          accentColor="indigo"       // closest Radix scale to your brand
          grayColor="slate"          // cool neutrals
          panelBackground="solid"    // or "translucent"
          radius="medium"            // none | small | medium | large | full
          scaling="100%"             // 90% | 95% | 100% | 105% | 110%
          appearance="inherit"       // inherit | light | dark
        >
          {children}
        </Theme>
      </body>
    </html>
  );
}
```

## Template — `theme-overrides.css`

Radix Themes uses a **12-step perceptual scale** per accent/gray. Each step has a defined semantic role — overriding only step 9/10 leaves a broken scale. Override all 12 (plus the alpha variants `--accent-a1..a12`) for a clean custom palette.

Radix step semantics:
- 1–2: backgrounds (`bg`, `bg-subtle`)
- 3: interactive subtle bg (hover on subtle)
- 4: interactive subtle bg (active on subtle)
- 5: interactive subtle bg (pressed on subtle)
- 6: borders (subtle)
- 7: borders (interactive, hover)
- 8: borders (interactive, active) — Radix uses `--focus-8` for focus rings
- 9: solid bg (buttons) — must be ≥ 4.5:1 contrast with white text
- 10: solid bg hover
- 11: text low-contrast
- 12: text high-contrast — must be ≥ 7:1 with bg

```css
/* theme-overrides.css — MUST load AFTER @radix-ui/themes/styles.css */

.radix-themes {
  /* ---------- Accent scale (12 steps + 12 alpha) ---------- */
  /* Replace with your brand scale. Use https://www.radix-ui.com/colors/custom
     to generate a scale from a single hex. */
  --accent-1:  oklch(99.0% 0.004 256);
  --accent-2:  oklch(97.5% 0.010 256);
  --accent-3:  oklch(94.5% 0.025 256);
  --accent-4:  oklch(91.0% 0.045 256);
  --accent-5:  oklch(86.5% 0.065 256);
  --accent-6:  oklch(80.0% 0.090 259);
  --accent-7:  oklch(71.5% 0.120 261);
  --accent-8:  oklch(63.0% 0.160 262);
  --accent-9:  oklch(54.6% 0.215 263);  /* your brand solid */
  --accent-10: oklch(50.0% 0.215 263);  /* brand hover */
  --accent-11: oklch(45.0% 0.200 264);
  --accent-12: oklch(25.0% 0.140 265);

  --accent-a1:  color-mix(in oklab, var(--accent-9) 2%,  transparent);
  --accent-a2:  color-mix(in oklab, var(--accent-9) 4%,  transparent);
  --accent-a3:  color-mix(in oklab, var(--accent-9) 8%,  transparent);
  --accent-a4:  color-mix(in oklab, var(--accent-9) 12%, transparent);
  --accent-a5:  color-mix(in oklab, var(--accent-9) 16%, transparent);
  --accent-a6:  color-mix(in oklab, var(--accent-9) 22%, transparent);
  --accent-a7:  color-mix(in oklab, var(--accent-9) 32%, transparent);
  --accent-a8:  color-mix(in oklab, var(--accent-9) 48%, transparent);
  --accent-a9:  var(--accent-9);
  --accent-a10: var(--accent-10);
  --accent-a11: var(--accent-11);
  --accent-a12: var(--accent-12);

  /* ---------- Gray scale ---------- */
  --gray-1:  oklch(99.0% 0 0);
  --gray-2:  oklch(97.5% 0 0);
  --gray-3:  oklch(94.0% 0 0);
  --gray-4:  oklch(91.0% 0 0);
  --gray-5:  oklch(86.8% 0 0);
  --gray-6:  oklch(80.5% 0 0);
  --gray-7:  oklch(70.5% 0 0);
  --gray-8:  oklch(60.0% 0 0);
  --gray-9:  oklch(43.9% 0 0);
  --gray-10: oklch(37.1% 0 0);
  --gray-11: oklch(26.9% 0 0);
  --gray-12: oklch(14.5% 0 0);

  /* ---------- Panels ---------- */
  --color-panel-solid: #ffffff;
  --color-panel-translucent: color-mix(in srgb, #ffffff 72%, transparent);

  /* ---------- Focus ring uses --focus-8 by convention ---------- */
  --focus-8: var(--accent-8);

  /* ---------- Radius factor ---------- */
  --radius-factor: 1;
}

.radix-themes.dark,
[data-is-root-theme="true"].dark {
  --accent-1:  oklch(16.0% 0.018 263);
  --accent-2:  oklch(18.5% 0.030 263);
  --accent-3:  oklch(22.0% 0.060 263);
  --accent-4:  oklch(26.0% 0.090 263);
  --accent-5:  oklch(30.0% 0.120 263);
  --accent-6:  oklch(35.0% 0.150 263);
  --accent-7:  oklch(42.0% 0.180 263);
  --accent-8:  oklch(50.0% 0.210 263);
  --accent-9:  oklch(54.6% 0.215 263);
  --accent-10: oklch(62.0% 0.210 263);
  --accent-11: oklch(75.0% 0.180 263);
  --accent-12: oklch(95.0% 0.040 263);

  --gray-1:  oklch(14.5% 0 0);
  --gray-2:  oklch(17.5% 0 0);
  --gray-3:  oklch(20.5% 0 0);
  --gray-4:  oklch(23.5% 0 0);
  --gray-5:  oklch(26.9% 0 0);
  --gray-6:  oklch(31.0% 0 0);
  --gray-7:  oklch(37.1% 0 0);
  --gray-8:  oklch(43.9% 0 0);
  --gray-9:  oklch(55.6% 0 0);
  --gray-10: oklch(61.0% 0 0);
  --gray-11: oklch(80.0% 0 0);
  --gray-12: oklch(98.5% 0 0);

  --color-panel-solid:       oklch(17.5% 0 0);
  --color-panel-translucent: color-mix(in srgb, oklch(17.5% 0 0) 72%, transparent);
}
```

## Mapping DESIGN.md → Radix Theme props

| DESIGN.md | Radix `<Theme>` prop |
|---|---|
| Brand hue (indigo, violet, blue) | `accentColor="indigo"` |
| Neutral temperature (warm/cool) | `grayColor="slate"` (cool) or `sand` (warm) |
| Panel style (solid/translucent) | `panelBackground="solid"` |
| Base radius (`--radius-md`) | `radius="small"` (≤4px) / `"medium"` (6-8px) / `"large"` (10-12px) |
| Size scaling | `scaling="100%"` |
| Mode | `appearance="dark"` / `"light"` |

## Radix accent scales (pick closest match)

Radix provides pre-built 12-step scales: `tomato, red, ruby, crimson, pink, plum, purple, violet, iris, indigo, blue, cyan, teal, jade, green, grass, bronze, gold, brown, orange, amber, yellow, lime, mint, sky`.

Match by hue dominance. For hybrid palettes, pick the closest and override step 9/10 in `theme-overrides.css`.

## Strategy — Radix Primitives (headless)

If the project uses individual `@radix-ui/react-*` primitives without Radix Themes, style them with Tailwind (typically via ShadCN — see `shadcn.md`). The primitives are unstyled; you bring your own CSS.

```tsx
import * as DialogPrimitive from "@radix-ui/react-dialog";

export const DialogContent = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Portal>
    <DialogPrimitive.Overlay className="fixed inset-0 z-50 bg-black/80 data-[state=open]:animate-fade-in" />
    <DialogPrimitive.Content
      ref={ref}
      className={cn(
        "fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2",
        "bg-surface text-fg border border-border rounded-lg p-6 shadow-lg",
        "data-[state=open]:animate-scale-in",
        "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-focus-ring",
        className
      )}
      {...props}
    />
  </DialogPrimitive.Portal>
));
```

Use `data-[state=open]` attribute selectors for state-driven animations — Radix sets `data-state` automatically on all primitives.
