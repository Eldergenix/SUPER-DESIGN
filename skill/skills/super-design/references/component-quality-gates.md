# Component Quality Gates

## Hard limits (blocks edit)

| Gate | Warn | Hard fail |
|---|---|---|
| File LOC | > 300 | > 500 |
| Function LOC | > 50 | > 80 |
| Cyclomatic complexity | > 10 | > 15 |
| Cognitive complexity | > 15 | > 25 |
| Max JSX depth | > 4 | > 6 |
| Max props | > 7 | > 10 |
| Max hooks per component | > 8 | > 12 |
| Hardcoded hex literal | any match | any match |
| Hardcoded rgb/hsl literal | any match | any match |
| Hardcoded px (outside scale) | any match | > 3 matches |
| Inline `style={{ color: "#..." }}` | any match | any match |
| Missing `alt=` on `<img>` | any match | any match |
| `:focus` without `:focus-visible` | any match | any match |
| `outline: none` without replacement | any match | any match |

## Token scale allowance

Pixel values NOT allowed outside these (which match the 4px base scale): `0, 1, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96`.

Exception: `1px` for borders, `2px` for focus offsets, and any value INSIDE a `tokens.json`, `tailwind.config.*`, `theme.ts`, `globals.css` `@theme` block, or a file path matching `**/DESIGN.md`.

## Scoring rubric (0–100)

```
LOC score (20 pts):         ≤200 → 20 | ≤300 → 15 | ≤500 → 8 | >500 → 0
Complexity (20 pts):        cyclo≤10 AND cognitive≤15 → 20 | ≤15/≤25 → 10 | else → 0
Token usage (20 pts):       0 hex/rgb/raw-px → 20 | 1-2 → 10 | 3+ → 0
A11y (15 pts):              axe 0 violations → 15 | 1-2 warn → 8 | errors → 0
Responsive (10 pts):        sm:/md:/lg: present → 10 | partial → 5 | none → 0
States defined (10 pts):    hover+focus-visible+disabled(+loading) → 10 | 2–3 → 6 | <2 → 0
Single responsibility (5 pts): one export default component → 5 | multi → 0
```

**Grade:** 90+ A (ship), 75–89 B (refine), 60–74 C (block), <60 F (rewrite).

## Detection patterns for hooks

### Hardcoded hex (block)
```regex
#([0-9a-fA-F]{3}){1,2}\b
```
Exception: inside string literals that look like CSS variable fallbacks or inside token files.

### Hardcoded rgb/rgba/hsl/hsla (block)
```regex
\b(rgb|rgba|hsl|hsla)\s*\(
```

### Hardcoded px outside scale (warn)
```regex
\b([0-9]+)px\b
```
Then post-filter: allowed values = {0, 1, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96}.

### Inline style color (block)
```regex
style=\{\{[^}]*color:\s*["'`]#
```

### Tailwind arbitrary values (warn)
```regex
\[#[0-9a-fA-F]+\]|\[[0-9]+px\]
```
Exception: `w-[100dvh]` and similar non-px values.

### `:focus` without `:focus-visible` (block)
```regex
:focus(?!-visible)
```
Only in `.css`, `.scss`, `.vue` style blocks.

### `outline: none` without replacement (warn)
```regex
outline:\s*none
```
Warn only; the hook should also check if `box-shadow` or `outline-offset` is set within the same rule.

### Missing `alt=` (block)
```regex
<img(?![^>]*\balt=)
```

### Animating disallowed property (warn)
```regex
transition[^;]*\b(width|height|top|left|margin|padding)\b
```

## ESLint configuration (installed alongside)

```js
{
  "rules": {
    "max-lines": ["warn", { "max": 300, "skipBlankLines": true }],
    "max-lines-per-function": ["warn", { "max": 50 }],
    "complexity": ["warn", 10],
    "max-depth": ["warn", 4],
    "max-params": ["warn", 4],
    "max-nested-callbacks": ["warn", 3],
    "react/no-multi-comp": "error",
    "sonarjs/cognitive-complexity": ["warn", 15],
    "sonarjs/no-duplicate-string": ["warn", { "threshold": 3 }],
    "sonarjs/no-identical-functions": "warn",
    "jsx-a11y/alt-text": "error",
    "jsx-a11y/anchor-has-content": "error",
    "jsx-a11y/aria-props": "error",
    "jsx-a11y/aria-role": "error",
    "jsx-a11y/click-events-have-key-events": "error",
    "jsx-a11y/no-static-element-interactions": "error",
    "jsx-a11y/label-has-associated-control": "error",
    "jsx-a11y/no-autofocus": "warn",
    "jsx-a11y/interactive-supports-focus": "error",
    "jsx-a11y/role-has-required-aria-props": "error"
  }
}
```

## Stylelint configuration

```json
{
  "rules": {
    "color-no-hex": [true, { "message": "Use var(--color-*) tokens instead of hex" }],
    "declaration-property-value-disallowed-list": {
      "/color|background|border|fill|stroke/": ["/^#/", "/^rgb/", "/^hsl/"],
      "/margin|padding|gap|font-size|border-radius/": ["/^\\d+px$/"]
    },
    "custom-property-pattern": "^(color|space|radius|font|shadow|duration|ease|semantic|text)-.+"
  }
}
```

## When to split a component

Extract sub-components when ANY of these trigger:
- File approaches 300 LOC
- JSX nests > 4 levels deep
- > 5 `useState` / `useEffect` / `useMemo` hooks in one component
- > 7 props — collapse related props into an object or extract
- Two distinct responsibilities (data fetching + presentation, or form + visualization)
- Reusable sub-UI emerges (e.g., the `<UserAvatar>` inside a `<Header>`)

Compound component pattern is preferred over prop explosion.
