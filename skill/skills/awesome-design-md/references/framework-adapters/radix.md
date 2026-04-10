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

```css
/* Overrides MUST load AFTER @radix-ui/themes/styles.css */

.radix-themes {
  /* Accent scale — Radix uses 1–12 steps.
     Replace with your brand's 12-step scale for full control.
     At minimum, override step 9 (solid bg). */
  --accent-9:  #4f46e5;
  --accent-10: #4338ca;
  --accent-a9: rgb(79 70 229 / 0.92);

  /* Gray scale */
  --gray-1:  #fafafa;
  --gray-2:  #f5f5f5;
  --gray-12: #171717;

  /* Panel */
  --color-panel-solid: #ffffff;
  --color-panel-translucent: rgb(255 255 255 / 0.72);

  /* Radius factor — all Radius scales derive from this */
  --radius-factor: 1;
}

.radix-themes.dark,
[data-is-root-theme="true"].dark {
  --gray-1:  #0a0a0a;
  --gray-2:  #171717;
  --gray-12: #fafafa;

  --color-panel-solid: #171717;
  --color-panel-translucent: rgb(23 23 23 / 0.72);

  --accent-9:  #6366f1;
  --accent-10: #818cf8;
}

/* Focus ring — Radix Themes uses --focus-8 */
.radix-themes {
  --focus-8: var(--accent-9);
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
