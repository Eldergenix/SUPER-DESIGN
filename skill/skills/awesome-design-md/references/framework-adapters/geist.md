# Framework Adapter: Vercel Geist

## Detection

- `package.json` contains `geist` (font), `@vercel/geist-ui`, or `@geist-ui/core`
- Imports of `GeistSans` / `GeistMono` from `geist/font/*`

## Strategy

Geist is three things that share a name:
1. **Geist font** — `geist` package with `GeistSans` and `GeistMono`, optimized for `next/font`
2. **Geist design tokens** — CSS variables (`--geist-foreground`, `--accents-*`, `--geist-radius`)
3. **Geist components** — Vercel-internal (`vercel.com/geist/design`); external consumers typically use `@geist-ui/core`

Set up the font, expose CSS variables matching the DESIGN.md tokens, and (optionally) wrap in `GeistProvider` when using `@geist-ui/core`.

## Template — Next.js App Router

```tsx
// app/layout.tsx
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import "./theme.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body className="font-sans bg-[var(--geist-background)] text-[var(--geist-foreground)]">
        {children}
      </body>
    </html>
  );
}
```

## Template — `theme.css`

```css
:root {
  /* Fonts exposed by geist/font */
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);

  /* Geist token set — extended from DESIGN.md */
  --geist-background:  #ffffff;
  --geist-foreground:  #171717;
  --geist-success:     #10b981;
  --geist-error:       #ef4444;
  --geist-warning:     #f59e0b;
  --geist-cyan:        #06b6d4;
  --geist-purple:      #8b5cf6;

  /* Accent scale 1–8 (Geist pattern) */
  --accents-1: #fafafa;
  --accents-2: #f4f4f5;
  --accents-3: #e4e4e7;
  --accents-4: #d4d4d8;
  --accents-5: #a1a1aa;
  --accents-6: #71717a;
  --accents-7: #52525b;
  --accents-8: #27272a;

  /* Brand workflow colors (Vercel signature) */
  --ship-red:     #ff5b4f;
  --preview-pink: #de1d8d;
  --develop-blue: #0a72ef;

  /* Shape + spacing */
  --geist-radius: 6px;
  --geist-gap:    16px;
  --geist-space:  4px;

  /* Shadow stack (Geist signature: shadow-as-border) */
  --shadow-border:  0 0 0 1px rgb(0 0 0 / 0.08);
  --shadow-sm:      0 2px 2px 0 rgb(0 0 0 / 0.04);
  --shadow-md:      0 0 0 1px rgb(0 0 0 / 0.08), 0 2px 2px 0 rgb(0 0 0 / 0.04), 0 8px 8px -8px rgb(0 0 0 / 0.04);

  /* Focus ring — Geist's canonical saturated blue */
  --ds-focus-color: hsl(212, 100%, 48%);
}

[data-theme="dark"] {
  --geist-background: #000000;
  --geist-foreground: #fafafa;

  --accents-1: #0a0a0a;
  --accents-2: #171717;
  --accents-3: #262626;
  --accents-4: #404040;
  --accents-5: #525252;
  --accents-6: #737373;
  --accents-7: #a3a3a3;
  --accents-8: #d4d4d8;

  --shadow-border: 0 0 0 1px rgb(255 255 255 / 0.12);
}

body {
  font-family: var(--font-sans), Arial, "Apple Color Emoji", "Segoe UI Emoji";
  font-feature-settings: "liga", "tnum";
  -webkit-font-smoothing: antialiased;
}

code, pre {
  font-family: var(--font-mono), ui-monospace, "SF Mono", Menlo;
  font-feature-settings: "liga";
}

:focus-visible {
  outline: 2px solid var(--ds-focus-color);
  outline-offset: 2px;
  border-radius: inherit;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Template — with `@geist-ui/core` provider

```tsx
import { GeistProvider, CssBaseline, Themes } from "@geist-ui/core";

const customTheme = Themes.createFromLight({
  type: "custom",
  palette: {
    success:    "#10b981",
    successLight: "#34d399",
    successDark:  "#059669",
    // ...override all the tokens you need
  },
  expressiveness: {
    shadowSmall:  "0 2px 2px 0 rgb(0 0 0 / 0.04)",
    shadowMedium: "0 0 0 1px rgb(0 0 0 / 0.08), 0 2px 2px 0 rgb(0 0 0 / 0.04)",
  },
  layout: {
    gap: "16px",
    radius: "6px",
  },
});

export default function App({ children }) {
  return (
    <GeistProvider themes={[customTheme]} themeType="custom">
      <CssBaseline />
      {children}
    </GeistProvider>
  );
}
```

## Rules for Geist projects

- Use `GeistSans` / `GeistMono` from `geist/font` with `next/font` — do NOT load from Google Fonts
- Enable `"liga"` OpenType feature globally (Geist's distinctive ligatures)
- Use `"tnum"` for tabular numbers in data-dense UI (tables, metrics)
- Shadow-as-border pattern: `box-shadow: 0 0 0 1px rgb(0 0 0 / 0.08)` instead of `border: 1px solid`
- Workflow colors (`ship`, `preview`, `develop`) reserved for deployment-state UI, not decorative
- Focus ring is Geist's saturated blue `hsl(212, 100%, 48%)`, not the brand accent
