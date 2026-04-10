# Framework Adapter: Tailwind CSS v4

## Detection

A project is Tailwind v4 if ANY of these hold:
- CSS file contains `@import "tailwindcss";`
- CSS file contains an `@theme { ... }` block
- `package.json` lists `"tailwindcss": "^4"` or `@tailwindcss/postcss` / `@tailwindcss/vite`
- No `tailwind.config.js` present (v4 no longer auto-generates one)

```bash
grep -rE '@import\s+"tailwindcss"|@theme\s*\{' ./src ./app ./styles 2>/dev/null
```

## Strategy

Convert the DESIGN.md token tables directly into an `@theme` block in `globals.css` (or `app.css`). Every token automatically becomes BOTH a CSS custom property on `:root` AND a utility class.

## Template — full design-token `@theme` block

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  /* ---------- Colors (from DESIGN.md §2) ---------- */
  --color-*: initial;
  --color-white: #fff;
  --color-black: #000;
  --color-transparent: transparent;
  --color-current: currentColor;

  --color-neutral-50:  #fafafa;
  --color-neutral-100: #f5f5f5;
  --color-neutral-500: #737373;
  --color-neutral-900: #171717;
  --color-neutral-950: #0a0a0a;

  --color-brand-500: #6366f1;
  --color-brand-600: #4f46e5;
  --color-brand-700: #4338ca;

  /* Semantic aliases — the ones components reference */
  --color-bg:              var(--color-neutral-50);
  --color-surface:         #ffffff;
  --color-surface-raised:  #ffffff;
  --color-fg:              var(--color-neutral-900);
  --color-fg-muted:        var(--color-neutral-500);
  --color-border:          var(--color-neutral-200);
  --color-accent:          var(--color-brand-600);
  --color-accent-hover:    var(--color-brand-700);
  --color-accent-fg:       #ffffff;
  --color-focus-ring:      var(--color-brand-500);
  --color-danger:          #ef4444;
  --color-success:         #10b981;
  --color-warning:         #f59e0b;

  /* ---------- Typography ---------- */
  --font-sans: "Inter Variable", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  --text-xs:   clamp(0.75rem,  0.70rem + 0.25vw, 0.875rem);
  --text-sm:   clamp(0.875rem, 0.80rem + 0.30vw, 1rem);
  --text-base: clamp(1rem,     0.92rem + 0.40vw, 1.125rem);
  --text-lg:   clamp(1.125rem, 1.00rem + 0.60vw, 1.375rem);
  --text-xl:   clamp(1.375rem, 1.15rem + 1.10vw, 1.75rem);
  --text-2xl:  clamp(1.75rem,  1.35rem + 2.00vw, 2.5rem);
  --text-3xl:  clamp(2.25rem,  1.60rem + 3.20vw, 3.75rem);
  --text-4xl:  clamp(3rem,     2.00rem + 5.00vw, 5rem);

  --text-base--line-height: 1.6;
  --text-lg--line-height:   1.5;
  --text-xl--line-height:   1.3;
  --text-2xl--line-height:  1.25;
  --text-3xl--line-height:  1.15;
  --text-4xl--line-height:  1.05;

  --text-xl--letter-spacing:  -0.01em;
  --text-2xl--letter-spacing: -0.02em;
  --text-3xl--letter-spacing: -0.025em;
  --text-4xl--letter-spacing: -0.03em;

  --font-weight-regular:  400;
  --font-weight-medium:   500;
  --font-weight-semibold: 600;
  --font-weight-bold:     700;

  /* ---------- Spacing (4px base) ---------- */
  --spacing: 0.25rem;

  /* ---------- Radii ---------- */
  --radius-none: 0;
  --radius-sm:   0.25rem;
  --radius-md:   0.375rem;
  --radius-lg:   0.5rem;
  --radius-xl:   0.75rem;
  --radius-2xl:  1rem;
  --radius-full: 9999px;

  /* ---------- Shadows ---------- */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
  --shadow-focus-ring: 0 0 0 3px var(--color-focus-ring);

  /* ---------- Breakpoints ---------- */
  --breakpoint-sm:  40rem;
  --breakpoint-md:  48rem;
  --breakpoint-lg:  64rem;
  --breakpoint-xl:  80rem;
  --breakpoint-2xl: 96rem;

  /* ---------- Motion ---------- */
  --duration-instant: 75ms;
  --duration-fast:    150ms;
  --duration-base:    200ms;
  --duration-slow:    300ms;
  --duration-slower:  500ms;

  --ease-out:    cubic-bezier(0.2, 0, 0, 1);
  --ease-in:     cubic-bezier(0.4, 0, 1, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);

  --animate-fade-in:  fade-in  var(--duration-base) var(--ease-out);
  --animate-slide-up: slide-up var(--duration-slow) var(--ease-out);
  --animate-scale-in: scale-in var(--duration-base) var(--ease-out);
}

@keyframes fade-in  { from { opacity: 0 } to { opacity: 1 } }
@keyframes slide-up { from { opacity: 0; transform: translateY(8px) } to { opacity: 1; transform: none } }
@keyframes scale-in { from { opacity: 0; transform: scale(0.95) } to { opacity: 1; transform: scale(1) } }

/* Dark-mode token overrides */
:root {
  color-scheme: light;
  --color-bg:             var(--color-neutral-50);
  --color-surface:        #ffffff;
  --color-surface-raised: #ffffff;
  --color-fg:             var(--color-neutral-900);
  --color-fg-muted:       var(--color-neutral-500);
  --color-border:         #e5e5e5;
}
.dark {
  color-scheme: dark;
  --color-bg:             var(--color-neutral-950);
  --color-surface:        var(--color-neutral-900);
  --color-surface-raised: #262626;
  --color-fg:             var(--color-neutral-50);
  --color-fg-muted:       #a3a3a3;
  --color-border:         #262626;
}

/* Reduced motion global guard */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Every token above auto-generates matching utilities:
- `bg-brand-500`, `bg-accent`, `bg-surface`
- `text-4xl`, `font-sans`, `font-semibold`
- `p-6`, `gap-4`, `px-5`
- `rounded-xl`, `shadow-lg`
- `sm:`, `md:`, `lg:`, `xl:`, `2xl:`
- `animate-fade-in`

## Reset a namespace before redefining

```css
@theme {
  --color-*: initial;  /* wipe default palette */
  --color-brand-500: #6366f1;
  /* ...only the colors you want */
}
```

## Dark mode options

```css
/* Class-based (.dark on <html>) — recommended for user toggle */
@custom-variant dark (&:where(.dark, .dark *));

/* Data attribute */
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

/* Hybrid: manual override + system fallback */
@custom-variant dark (
  &:where([data-theme=dark], [data-theme=dark] *),
  &:where(:not([data-theme=light], [data-theme=light] *)) and (prefers-color-scheme: dark)
);
```
