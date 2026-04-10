# Design System

See `AGENTS.md` and `DESIGN.md` at project root.

## Hard rules

- Reference tokens from `DESIGN.md`; never emit literal `#hex`, `rgb()`, `hsl()`, or unscaled `px`
- Every interactive element: `hover`, `focus-visible`, `active`, `disabled`
- `:focus-visible` only; 3px outline, 2px offset, 3:1 contrast
- Animate only `transform` and `opacity`; respect `prefers-reduced-motion`
- Max 300 LOC per component file
- Min 44×44 touch targets
- Responsive at 320/375/768/1024/1440/1920

Full skill: `.claude/skills/super-design/SKILL.md`.
