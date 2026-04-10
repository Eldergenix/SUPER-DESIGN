# awesome-design-md

> A production-grade design-system skill for AI coding agents.
> Reads `DESIGN.md` as a closed token layer, generates framework-native
> theme code, and enforces UI/UX quality gates on every edit via hooks.
> Ships with real automation — not just documentation.

**Compatible with:** Claude Code · Claude · Cursor · OpenAI Codex · GitHub Copilot · Gemini CLI · Google Antigravity · Windsurf · Zed · Cline · Continue.dev · Aider

---

## What it actually does

| Capability | Tool |
|---|---|
| Reads your `DESIGN.md` as a closed token layer | SKILL.md guidance |
| Validates DESIGN.md against the schema | `lint-design-md.sh` |
| Verifies WCAG 2.2 AA contrast on every semantic color pair | `contrast-check.mjs` (hex, rgb, OKLCH) |
| Generates framework-native theme files (Tailwind v4, ShadCN, MUI) | `generate-theme.mjs` |
| Blocks hardcoded colors / off-scale px / missing alt / `:focus` without `:focus-visible` on every edit | `validate-tokens.sh` (PostToolUse hook) |
| Blocks components > 500 LOC, JSX depth > 6, > 12 hooks, missing `focus-visible` | `validate-component.sh` (PostToolUse hook) |
| Scores every component 0–100 with letter grade | `quality-score.sh` |
| Batch-audits an entire `src/` directory and sorts worst-first | `audit.sh` |
| Crops a screenshot for focused vision-model inspection | `crop-region.sh` |
| Screenshots a URL/file via Playwright for visual diffing | `screenshot-component.mjs` |
| Pixel-diffs two images with self-scoring (0–100) | `visual-diff.mjs` (odiff + pixelmatch fallback) |
| Runs 13 self-tests against good/bad fixtures | `test.sh` |
| Installs cross-agent shim files so Claude/Cursor/Codex/Gemini/Copilot/Windsurf/Cline/Continue all read the same design system | `install.sh` |

## Install

### Claude Code — plugin marketplace

```
/plugin marketplace add VoltAgent/awesome-design-md
/plugin install awesome-design-md@awesome-design-md
```

### Claude Code / any agent — git clone + bash

```bash
git clone https://github.com/VoltAgent/awesome-design-md.git /tmp/awesome-design-md
cd /path/to/your/project

# Preview what will change
bash /tmp/awesome-design-md/skill/install.sh --project --dry-run

# Actually install
bash /tmp/awesome-design-md/skill/install.sh --project
```

### npm / npx

```bash
cd /path/to/your/project
npx awesome-design-md --project
```

Works without bash on Windows — `bin/install.js` has a pure-Node fallback.

### Uninstall

```bash
bash .claude/skills/awesome-design-md/scripts/install.sh --uninstall
```

Removes the skill directory, strips `awesome-design-md` hooks from `settings.json`, removes shim files. Does NOT remove your `DESIGN.md` (it's your design system).

## What gets installed (project mode)

```
your-project/
├── DESIGN.md                                     # Enhanced template (edit with your tokens)
├── AGENTS.md                                     # Universal agent instructions
├── CLAUDE.md                                     # @imports AGENTS.md + DESIGN.md
├── GEMINI.md                                     # @imports AGENTS.md + DESIGN.md
├── .eslintrc.design-md.json                      # Ship-ready ESLint config
├── .stylelintrc.design-md.json                   # Ship-ready Stylelint config
├── playwright.design-md.config.ts                # Visual-regression config (320/375/768/1024/1440/1920 + dark + forced-colors)
├── .claude/
│   ├── settings.json                             # Hooks merged into existing config
│   ├── awesome-design-md.install.json            # Version manifest
│   └── skills/awesome-design-md/                 # Full skill with SKILL.md + references + scripts
├── .cursor/rules/awesome-design-md.mdc           # Cursor rule (alwaysApply)
├── .github/copilot-instructions.md               # Copilot instructions
├── .windsurf/rules/design-system.md              # Windsurf rule
├── .continue/rules/design-system.md              # Continue.dev rule
└── .clinerules/design-system.md                  # Cline rule
```

## Usage

After install, just ask your agent to build UI:

> "Build me a dashboard card with a stats grid and a chart placeholder"

The skill automatically:
1. Reads `DESIGN.md`
2. Detects your framework (`detect-framework.sh`)
3. Loads the matching adapter (`references/framework-adapters/<name>.md`)
4. Uses only tokens from DESIGN.md
5. Defines all required states from `STATE_MATRIX.yaml`
6. Validates every edit via PostToolUse hooks

### Screenshot → code

Paste or attach a screenshot and ask:

> "Recreate this screenshot using my DESIGN.md"

The skill runs the 7-pass extraction loop from `references/screenshot-to-code-workflow.md`:

1. **Layout** — 12-col grid decomposition
2. **Color** — per-region extraction, OCR-grounded
3. **Typography** — font size/weight/tracking, snapped to scale
4. **Spacing & components** — snap to 4px/8px, identify primitives
5. **Reconcile** — diff extracted tokens against DESIGN.md, propose a patch for any NEW tokens (NO silent invention)
6. **Code gen** — uses ONLY reconciled tokens
7. **Visual verify** — render, screenshot, pixel-diff, self-score, iterate ≤ 3 times

### Quality gates

```bash
# Score a single component
bash .claude/skills/awesome-design-md/scripts/quality-score.sh src/components/Button.tsx
# { "totalScore": 92, "grade": "A", "breakdown": { ... } }

# Batch audit — sorted worst-first on stderr
bash .claude/skills/awesome-design-md/scripts/audit.sh src/

# Visual diff
node .claude/skills/awesome-design-md/scripts/visual-diff.mjs reference.png actual.png diff.png 0.1

# WCAG contrast check on your DESIGN.md
node .claude/skills/awesome-design-md/scripts/contrast-check.mjs DESIGN.md

# Generate theme file from DESIGN.md
node .claude/skills/awesome-design-md/scripts/generate-theme.mjs DESIGN.md --target=tailwind-v4 --out=app/globals.css
```

## Hard rules enforced on every edit

The `PostToolUse` hooks block or warn on these in any `.tsx/.jsx/.vue/.svelte/.css/.scss` file (excluding token/theme/config files):

**Blocks (exit 2):**
- Literal `#hex`, `rgb()`, `hsl()`, `oklch()`, `lab()` colors outside `var()` wrappers
- Inline `style={{ color: '#...' }}`
- `<img>` without `alt`
- File > 500 LOC
- JSX depth > 6
- > 12 hooks in one component
- Interactive element without `:focus-visible` (WCAG 2.2 AA blocker)
- > 3 off-scale `px` values

**Warns (exit 0, non-blocking context):**
- `:focus` without `:focus-visible`
- `outline: none` without replacement `box-shadow`
- Animating `width`/`height`/`top`/`left`/`margin`/`padding`
- Missing `forced-colors` declaration on interactive surfaces
- Missing responsive breakpoints on layout files
- Primitive-token references from components (should use semantic layer)
- `async onClick` without `aria-busy`
- Component files > 300 LOC
- > 8 hooks in one component

**Exempt from token literal checks** (these files ARE the token layer):
`tailwind.config.*`, `theme.ts`, `globals.css`, `tokens.json`, `DESIGN.md`, `STATE_MATRIX.yaml`.

## Quality score rubric (0–100)

| Dimension | Max | Check |
|---|---|---|
| LOC | 20 | ≤200 → 20 · ≤300 → 15 · ≤500 → 8 · else → 0 |
| Complexity | 20 | cyclomatic ≤10 AND JSX depth ≤4 AND hooks ≤8 → 20 |
| Tokens | 20 | 0 literals AND 0 primitive refs → 20 · 0 literals + ≤2 primitive → 15 · ≤2 literals → 8 |
| A11y | 15 | 0 issues → 15 · ≤2 → 8 |
| Responsive | 10 | ≥3 matches → 10 · ≥1 → 5 |
| States | 10 | hover + focus-visible + disabled + active → 10 |
| Single responsibility | 5 | ≤2 exports → 5 |

**Grades:** 90+ A (ship) · 75–89 B (refine) · 60–74 C (block) · <60 F (rewrite)

## What's in the DESIGN.md template

The enhanced `DESIGN.md` template (shipped to your project on install) includes:

- **Three-layer color system**: primitive → semantic → component, with **enforced semantic-over-primitive** rule in hooks
- **OKLCH primary values** with sRGB hex fallbacks (wide-gamut support)
- **Forced-colors mode** guidance (Windows High Contrast)
- `prefers-contrast: more` fallback
- **Font loading strategy** — `font-display`, preload, fallback metrics, CLS prevention
- **Signature weight 510** (Linear-style between-weight)
- **Fluid type scale** with clamp() tokens tied to `--leading-*` / `--tracking-*`
- **Inset/stack/inline spacing** — Adobe Spectrum / Carbon pattern
- **Logical properties** guidance (`margin-inline`, `padding-block`) for i18n/RTL
- **Double-layer focus ring** pattern (`0 0 0 2px bg, 0 0 0 5px focus-ring`)
- **Skeleton colors derived from surface tokens** (auto-themes with dark mode)
- **Delay tokens** (tooltip-show, hover-intent)
- `dark_mode_strategy` in the Meta block (class / media / class-with-system-fallback)

## Tests

```bash
bash .claude/skills/awesome-design-md/scripts/test.sh
```

Runs 13 self-tests against good/bad component fixtures:
- validate-tokens passes on tokenized code
- validate-tokens blocks hex, inline color, img-no-alt
- validate-tokens IGNORES hex in comments (no false positives)
- validate-component blocks missing `:focus-visible` on interactive elements
- quality-score reports A-grade on clean code, F-grade on bad
- lint-design-md validates the bundled template
- detect-framework emits valid JSON
- contrast-check runs against the bundled DESIGN.md
- generate-theme emits valid output for tailwind-v4 / shadcn / mui

## License

MIT © VoltAgent

## Links

- [awesome-design-md repo](https://github.com/VoltAgent/awesome-design-md)
- [Google Stitch DESIGN.md format](https://stitch.withgoogle.com/docs/design-md/overview/)
- [AGENTS.md open standard](https://agents.md/)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks)
- [DTCG Design Tokens spec](https://www.designtokens.org/tr/drafts/format/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [CHANGELOG](./CHANGELOG.md)
- [CONTRIBUTING](./CONTRIBUTING.md)
