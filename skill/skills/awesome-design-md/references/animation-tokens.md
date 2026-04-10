# Animation & Micro-interaction Tokens

**Philosophy:** Advanced but minimal. One signature motion per surface. Default is static. Animate only with stated purpose.

## Duration tokens

```css
--duration-instant: 75ms;   /* tooltip appear, focus ring, checkbox toggle */
--duration-fast:    150ms;  /* button press, hover, most state flips */
--duration-base:    200ms;  /* default transitions, modals in */
--duration-slow:    300ms;  /* drawers, toasts, complex enters */
--duration-slower:  500ms;  /* page transitions, narrative reveals */
```

Industry consensus (Material 3, Carbon, IBM): 150 / 200 / 300ms covers ~90% of UI. Anything > 500ms must be a deliberate narrative moment.

## Easing tokens

```css
--ease-out:    cubic-bezier(0.2, 0, 0, 1);          /* enter / reveal */
--ease-in:     cubic-bezier(0.4, 0, 1, 1);          /* exit / dismiss */
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);        /* move / morph — Material standard */
--ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275); /* playful bounce */
--ease-ios:    cubic-bezier(0.25, 0.1, 0.25, 1);    /* iOS system */
```

## Recipes

| Pattern | Tailwind utility | Framer Motion | Duration | Easing | Use |
|---|---|---|---|---|---|
| **Button press** | `active:scale-[0.97] transition-transform duration-75 ease-out` | `whileTap={{ scale: 0.97 }}` | instant | out | Any clickable |
| **Hover lift** | `hover:-translate-y-0.5 hover:shadow-md transition duration-150` | `whileHover={{ y: -2 }}` | fast | out | Cards, CTAs |
| **Focus ring** | `focus-visible:ring-[3px] focus-visible:ring-offset-2 transition-[box-shadow] duration-75` | (CSS only) | instant | out | All inputs, buttons |
| **Skeleton shimmer** | custom `@keyframes shimmer` on gradient | n/a | 2000ms loop | in-out | Data loading |
| **Toast slide-in** | from-y-5 to-y-0 opacity-0 to-100 duration-300 ease-out | `initial={{y:20,opacity:0}} animate={{y:0,opacity:1}} spring(300,30)` | slow | out | Notifications |
| **Modal scale-in** | scale-95 to-100 opacity-0 to-100 duration-200 ease-out | `initial={{scale:0.95,opacity:0}} animate={{scale:1,opacity:1}}` | base | out | Dialogs |
| **Drawer slide-in** | translate-x-full to-0 duration-300 ease-out | `initial={{x:'100%'}} animate={{x:0}}` | slow | out | Side panels |
| **Stagger list** | `animation-delay: calc(var(--i) * 40ms)` | `staggerChildren: 0.04` | base | out | Lists ≤ 20 items |
| **Page transition** | `::view-transition-*` | `startViewTransition()` | slow | out | Route changes |

## Canonical Framer Motion variants

```ts
export const fadeUp = {
  hidden: { opacity: 0, y: 8 },
  show:   { opacity: 1, y: 0, transition: { duration: 0.2, ease: [0.2, 0, 0, 1] } },
};

export const listStagger = {
  show: { transition: { staggerChildren: 0.04, delayChildren: 0.08 } },
};

export const toastSpring = {
  initial: { y: 20, opacity: 0 },
  animate: { y: 0,  opacity: 1, transition: { type: 'spring', stiffness: 300, damping: 30 } },
  exit:    { y: 20, opacity: 0, transition: { duration: 0.15 } },
};
```

## Plain CSS equivalents

```css
.fade-up {
  opacity: 0;
  transform: translateY(8px);
  transition:
    opacity   var(--duration-base) var(--ease-out),
    transform var(--duration-base) var(--ease-out);
}
.fade-up[data-show] {
  opacity: 1;
  transform: none;
}

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
```

## Reduced motion (REQUIRED)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration:  0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior:     auto   !important;
  }
  /* Replace movement with opacity-only fade */
  .fade-up,
  .slide-in,
  .scale-in { transform: none; }
}
```

**Don't kill all motion** — replace movement with opacity/color change (per web.dev and WCAG C39).

## When to animate vs. stay static

**Animate when:**
- State is changing and user needs to track what moved
- New content enters/exits the DOM
- Interactive element needs affordance feedback
- It hides latency (skeleton, shimmer, progress)

**Stay static when:**
- Dense data (tables, code, forms)
- Motion would compete with content being read
- Decorative use on utility surfaces (dashboards, settings)
- Change is instantaneous and semantic (tab switch to cached content)

**Default is static.** Add motion only with a stated purpose.

## Anti-patterns (the hook will warn on these)

- Animating `width`, `height`, `top`, `left`, `margin`, `padding` — triggers layout reflow
- Durations > 400ms on frequent actions (feels sluggish)
- Bounce/elastic easing on destructive or professional UI
- Parallax or autoplay without reduced-motion guard
- Staggering > 20 items (use a single fade instead)
- Animating on every render due to `key` churn
- `transition: all` on an element with unpredictable child changes

## Philosophy from the masters

**Apple / Linear / Stripe / Vercel:** One signature motion per surface, 150–300ms, ease-out on enter, ease-in on exit, `transform` + `opacity` only, compositor-layer hinted with `will-change` sparingly.
