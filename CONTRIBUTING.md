# Contributing to Super Design

Thanks for contributing.

This repository ships two things:

1. **Super Design** — the installable AI skill under [`skill/`](./skill/) that enforces production-grade UI/UX on AI-generated code.
2. **The DESIGN.md collection** — 54 reference `DESIGN.md` files under [`super-design-md/`](./super-design-md/) extracted from real developer-focused websites.

Different contributions go to different paths.

## Contributing to the skill

Extending the `scripts/`, `references/`, or `SKILL.md` of Super Design? See [`skill/CONTRIBUTING.md`](./skill/CONTRIBUTING.md) for:

- Development workflow (`bash skill/skills/super-design/scripts/test.sh` must stay green)
- Code style rules (no `|| echo 0`, no shell-interpolation-into-Python, paths double-quoted)
- How to add a new framework adapter
- How to add a new hook rule with a matching fixture test
- Release process

All PRs to the skill MUST pass the 13-test self-test suite.

## Contributing to the DESIGN.md collection

### Request a new site

To request a DESIGN.md for a website, [open an issue](https://github.com/Eldergenix/SUPER-DESIGN/issues/new?template=design-md-request.yml) with the website URL.

### Improve an existing DESIGN.md

1. **Open an issue first** describing the change — get feedback from maintainers before you PR.
2. Read the existing file and compare against the live site.
3. Fix incorrect hex values, missing tokens, or weak descriptions. Use OKLCH alongside sRGB hex where possible.
4. Update `preview.html` and `preview-dark.html` if your changes affect visible tokens.
5. Run the schema linter against your updated file:
   ```bash
   bash skill/skills/super-design/scripts/lint-design-md.sh super-design-md/<site>/DESIGN.md
   ```
6. Verify contrast (optional but recommended):
   ```bash
   node skill/skills/super-design/scripts/contrast-check.mjs super-design-md/<site>/DESIGN.md
   ```
7. Open a PR with a clear before/after rationale.

### Guidelines for new DESIGN.md files

Every new DESIGN.md should follow the enhanced template structure shipped with the skill ([`skill/skills/super-design/DESIGN.md`](./skill/skills/super-design/DESIGN.md)):

- Sections 0–10, numbered consistently
- Three-layer color system (primitive → semantic → component)
- OKLCH primary values with sRGB hex fallbacks
- Full typography hierarchy table with size/weight/leading/tracking
- Inset/stack/inline spacing roles
- Component state matrix with `:focus-visible`, disabled, loading
- Motion tokens + reduced-motion guard
- Forced-colors mode guidance
- Agent prompt guide section

## License

By contributing, you agree your contributions are provided under the repository MIT license (see [`LICENSE`](./LICENSE)). Extracted DESIGN.md files represent publicly visible CSS values; contributors must not upload proprietary assets.
