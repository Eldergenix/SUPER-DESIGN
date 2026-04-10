# Framework Adapter: Tailwind CSS v3

## Detection

- `package.json` → `tailwindcss` version starts with `3.` or `^3`
- `tailwind.config.{js,ts,cjs,mjs}` exists at project root
- CSS uses `@tailwind base; @tailwind components; @tailwind utilities;`
- No `@import "tailwindcss"` / no `@theme` block

## Strategy

Drop tokens into `tailwind.config.js` under `theme.extend` (preserves defaults) and expose CSS variables from `globals.css` so runtime-themeable values (dark mode, user preferences) can be swapped without rebuilding.

## Template — `tailwind.config.js`

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    "./app/**/*.{ts,tsx,js,jsx}",
    "./components/**/*.{ts,tsx,js,jsx}",
    "./src/**/*.{ts,tsx,js,jsx}",
  ],
  safelist: [
    { pattern: /(bg|text|border|ring)-(primary|secondary|accent|muted|danger|success|warning)/ },
  ],
  theme: {
    container: {
      center: true,
      padding: "1rem",
      screens: { "2xl": "1400px" },
    },
    screens: {
      sm: "640px", md: "768px", lg: "1024px", xl: "1280px", "2xl": "1536px",
    },
    extend: {
      colors: {
        bg:             "hsl(var(--color-bg) / <alpha-value>)",
        surface:        "hsl(var(--color-surface) / <alpha-value>)",
        "surface-raised": "hsl(var(--color-surface-raised) / <alpha-value>)",
        fg:             "hsl(var(--color-fg) / <alpha-value>)",
        "fg-muted":     "hsl(var(--color-fg-muted) / <alpha-value>)",
        border:         "hsl(var(--color-border) / <alpha-value>)",
        accent: {
          DEFAULT: "hsl(var(--color-accent) / <alpha-value>)",
          hover:   "hsl(var(--color-accent-hover) / <alpha-value>)",
          fg:      "hsl(var(--color-accent-fg) / <alpha-value>)",
        },
        danger:  "hsl(var(--color-danger) / <alpha-value>)",
        success: "hsl(var(--color-success) / <alpha-value>)",
        warning: "hsl(var(--color-warning) / <alpha-value>)",
        "focus-ring": "hsl(var(--color-focus-ring) / <alpha-value>)",
      },
      fontFamily: {
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "ui-monospace", "Menlo"],
      },
      fontSize: {
        xs:   ["clamp(0.75rem,  0.70rem + 0.25vw, 0.875rem)", { lineHeight: "1.5" }],
        sm:   ["clamp(0.875rem, 0.80rem + 0.30vw, 1rem)",     { lineHeight: "1.5" }],
        base: ["clamp(1rem,     0.92rem + 0.40vw, 1.125rem)", { lineHeight: "1.6" }],
        lg:   ["clamp(1.125rem, 1.00rem + 0.60vw, 1.375rem)", { lineHeight: "1.5", letterSpacing: "-0.01em" }],
        xl:   ["clamp(1.375rem, 1.15rem + 1.10vw, 1.75rem)",  { lineHeight: "1.3", letterSpacing: "-0.015em" }],
        "2xl":["clamp(1.75rem,  1.35rem + 2.00vw, 2.5rem)",   { lineHeight: "1.25", letterSpacing: "-0.02em" }],
        "3xl":["clamp(2.25rem,  1.60rem + 3.20vw, 3.75rem)",  { lineHeight: "1.15", letterSpacing: "-0.025em" }],
        "4xl":["clamp(3rem,     2.00rem + 5.00vw, 5rem)",     { lineHeight: "1.05", letterSpacing: "-0.03em" }],
      },
      spacing: {
        // 4px base — Tailwind's default already covers this
      },
      borderRadius: {
        sm: "0.25rem", md: "0.375rem", lg: "0.5rem", xl: "0.75rem", "2xl": "1rem",
      },
      boxShadow: {
        xs: "0 1px 2px 0 rgb(0 0 0 / 0.05)",
        sm: "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)",
        md: "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)",
        lg: "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)",
        xl: "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)",
        "focus-ring": "0 0 0 3px hsl(var(--color-focus-ring))",
      },
      transitionDuration: {
        instant: "75ms", fast: "150ms", base: "200ms", slow: "300ms", slower: "500ms",
      },
      transitionTimingFunction: {
        out:     "cubic-bezier(0.2, 0, 0, 1)",
        in:      "cubic-bezier(0.4, 0, 1, 1)",
        "in-out":"cubic-bezier(0.4, 0, 0.2, 1)",
        spring:  "cubic-bezier(0.175, 0.885, 0.32, 1.275)",
      },
      keyframes: {
        "fade-in":  { "0%": { opacity: 0 }, "100%": { opacity: 1 } },
        "slide-up": { "0%": { opacity: 0, transform: "translateY(8px)" }, "100%": { opacity: 1, transform: "none" } },
        "scale-in": { "0%": { opacity: 0, transform: "scale(0.95)" }, "100%": { opacity: 1, transform: "scale(1)" } },
        shimmer:    { "0%": { backgroundPosition: "200% 0" }, "100%": { backgroundPosition: "-200% 0" } },
      },
      animation: {
        "fade-in":  "fade-in 200ms cubic-bezier(0.2,0,0,1)",
        "slide-up": "slide-up 300ms cubic-bezier(0.2,0,0,1)",
        "scale-in": "scale-in 200ms cubic-bezier(0.2,0,0,1)",
        shimmer:    "shimmer 2s ease-in-out infinite",
      },
    },
  },
  plugins: [
    require("tailwindcss-animate"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
  ],
};
```

## Template — `globals.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* HSL triplets — no hsl() wrapper, Tailwind wraps via <alpha-value> */
    --color-bg:              0 0% 98%;
    --color-surface:         0 0% 100%;
    --color-surface-raised:  0 0% 100%;
    --color-fg:              0 0% 9%;
    --color-fg-muted:        0 0% 45%;
    --color-border:          0 0% 90%;
    --color-accent:          243 75% 59%;
    --color-accent-hover:    243 75% 51%;
    --color-accent-fg:       0 0% 100%;
    --color-focus-ring:      243 75% 59%;
    --color-danger:          0 84% 60%;
    --color-success:         160 84% 39%;
    --color-warning:         38 92% 50%;

    --font-sans: "Inter Variable", ui-sans-serif, system-ui, sans-serif;
    --font-mono: "JetBrains Mono", ui-monospace, Menlo;
  }

  .dark {
    --color-bg:              0 0% 4%;
    --color-surface:         0 0% 9%;
    --color-surface-raised:  0 0% 15%;
    --color-fg:              0 0% 98%;
    --color-fg-muted:        0 0% 64%;
    --color-border:          0 0% 15%;
    --color-accent:          243 75% 68%;
    --color-accent-hover:    243 75% 75%;
  }

  * { @apply border-border; }
  body { @apply bg-bg text-fg font-sans antialiased; }

  :focus-visible {
    @apply outline-none ring-[3px] ring-focus-ring ring-offset-2;
  }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## Hex → HSL triplet conversion

For each token, convert `#RRGGBB` → space-separated `H S% L%` (no `hsl()` wrapper, no commas). Use a small helper:

```js
function hexToHslTriplet(hex) {
  const r = parseInt(hex.slice(1,3),16)/255;
  const g = parseInt(hex.slice(3,5),16)/255;
  const b = parseInt(hex.slice(5,7),16)/255;
  const max = Math.max(r,g,b), min = Math.min(r,g,b);
  const l = (max+min)/2;
  let h, s;
  if (max === min) { h = s = 0; }
  else {
    const d = max - min;
    s = l > 0.5 ? d/(2-max-min) : d/(max+min);
    switch (max) {
      case r: h = (g-b)/d + (g<b?6:0); break;
      case g: h = (b-r)/d + 2; break;
      case b: h = (r-g)/d + 4; break;
    }
    h *= 60;
  }
  return `${h.toFixed(0)} ${(s*100).toFixed(0)}% ${(l*100).toFixed(0)}%`;
}
// hexToHslTriplet('#6366f1') → '239 84% 67%'
```
