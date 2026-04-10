---
name: Design System
description: Enforces DESIGN.md tokens and component quality on UI edits
alwaysApply: true
globs: "**/*.{tsx,jsx,ts,js,vue,svelte,css,scss,astro}"
---

# Design System Rules

Read `DESIGN.md` at the project root before any UI work.

- No hardcoded colors/rgb/hsl/unscaled px — reference tokens from DESIGN.md
- Every interactive element: `hover`, `focus-visible`, `active`, `disabled`
- `:focus-visible` only; 3px outline, 2px offset, 3:1 contrast
- Animate only `transform` and `opacity`; respect `prefers-reduced-motion`
- Max 300 LOC per component
- Min 44×44 touch targets
- Responsive at 320/375/768/1024/1440/1920

Full skill: `.claude/skills/awesome-design-md/SKILL.md`.
