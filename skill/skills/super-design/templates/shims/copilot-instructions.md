# GitHub Copilot Instructions

See `AGENTS.md` and `DESIGN.md` at the project root.

When generating UI code:

- Reference tokens from `DESIGN.md`; never emit literal `#hex`, `rgb()`, `hsl()`, or unscaled `px` values
- Every interactive element needs `hover`, `focus-visible`, `active`, `disabled` states
- Use `:focus-visible`, not `:focus`, for keyboard focus rings (3px outline, 2px offset)
- Animate only `transform` and `opacity`; respect `prefers-reduced-motion`
- Keep components under 300 LOC; extract sub-components when deeper
- Min 44×44 touch targets, 8px gap
- Responsive at 320 / 375 / 768 / 1024 / 1440 / 1920

The full design-system skill (including framework adapters for Tailwind v3/v4, ShadCN, MUI, Radix, and Geist) is at `.claude/skills/super-design/`.
