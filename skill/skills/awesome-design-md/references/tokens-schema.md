# Design Tokens Schema (DTCG-compatible)

Uses the W3C Design Tokens Community Group (DTCG) format, stable v2025.10.

## Core structure

Every token is a JSON object with:
- `$value` — the actual value
- `$type` — category: `color`, `dimension`, `fontFamily`, `fontWeight`, `fontSize`, `lineHeight`, `letterSpacing`, `duration`, `cubicBezier`, `number`
- `$description` — optional human-readable explanation

Composite types: `shadow`, `border`, `gradient`, `typography`, `transition`.

Aliases use `"{group.token}"` syntax.

## Example: Linear-inspired dark + indigo

```json
{
  "$schema": "https://design-tokens.github.io/community-group/format/",
  "color": {
    "indigo": {
      "400": { "$type": "color", "$value": "#7B86DC" },
      "500": { "$type": "color", "$value": "#5E6AD2", "$description": "Signature indigo" },
      "600": { "$type": "color", "$value": "#4C5AC7" }
    },
    "neutral": {
      "50":  { "$type": "color", "$value": "#F7F8F8" },
      "500": { "$type": "color", "$value": "#8A8F98" },
      "800": { "$type": "color", "$value": "#1C1D1F" },
      "900": { "$type": "color", "$value": "#0F1011" },
      "950": { "$type": "color", "$value": "#08090A" }
    }
  },
  "semantic": {
    "bg":      { "base":    { "$type": "color", "$value": "{color.neutral.950}" },
                 "surface": { "$type": "color", "$value": "{color.neutral.900}" },
                 "raised":  { "$type": "color", "$value": "{color.neutral.800}" } },
    "fg":      { "default": { "$type": "color", "$value": "{color.neutral.50}" },
                 "muted":   { "$type": "color", "$value": "{color.neutral.500}" } },
    "accent":  { "default": { "$type": "color", "$value": "{color.indigo.500}" },
                 "hover":   { "$type": "color", "$value": "{color.indigo.400}" } }
  },
  "space": {
    "1": { "$type": "dimension", "$value": { "value": 4,  "unit": "px" } },
    "2": { "$type": "dimension", "$value": { "value": 8,  "unit": "px" } },
    "4": { "$type": "dimension", "$value": { "value": 16, "unit": "px" } }
  },
  "radius": {
    "md":  { "$type": "dimension", "$value": { "value": 6, "unit": "px" } },
    "lg":  { "$type": "dimension", "$value": { "value": 8, "unit": "px" } }
  },
  "font": {
    "family": { "sans": { "$type": "fontFamily", "$value": ["Inter Variable", "system-ui"] } },
    "weight": { "regular": { "$type": "fontWeight", "$value": 400 },
                "medium":  { "$type": "fontWeight", "$value": 510 } }
  },
  "typography": {
    "body": {
      "$type": "typography",
      "$value": {
        "fontFamily": "{font.family.sans}",
        "fontWeight": "{font.weight.regular}",
        "fontSize":   { "value": 14, "unit": "px" },
        "lineHeight": 1.5,
        "letterSpacing": { "value": -0.1, "unit": "px" }
      }
    }
  },
  "shadow": {
    "low": {
      "$type": "shadow",
      "$value": {
        "color":   "#00000066",
        "offsetX": { "value": 0, "unit": "px" },
        "offsetY": { "value": 1, "unit": "px" },
        "blur":    { "value": 2, "unit": "px" },
        "spread":  { "value": 0, "unit": "px" }
      }
    }
  },
  "duration": {
    "fast": { "$type": "duration", "$value": "150ms" },
    "base": { "$type": "duration", "$value": "200ms" }
  },
  "ease": {
    "out":    { "$type": "cubicBezier", "$value": [0.2, 0, 0, 1] },
    "in-out": { "$type": "cubicBezier", "$value": [0.4, 0, 0.2, 1] }
  }
}
```

## Naming hierarchy (3 layers)

1. **Primitive** — raw values (`color.indigo.500`, `space.4`)
2. **Semantic** — role-based aliases to primitives (`semantic.accent.default` → `{color.indigo.500}`)
3. **Component** — per-component references to semantics (`button.primary.bg` → `{semantic.accent.default}`)

**Rule:** components NEVER reference primitives directly. They reference the semantic layer. This lets you re-theme by swapping primitive→semantic mappings without touching components.

## Tooling

- **Style Dictionary 4+** — transforms DTCG JSON to CSS/SCSS/JS/iOS/Android
- **Terrazzo** — DTCG-native build pipeline with plugins
- **Tokens Studio for Figma** — exports DTCG JSON via Git sync
