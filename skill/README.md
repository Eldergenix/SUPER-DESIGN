# awesome-design-md (skill)

> A production-grade design system skill for AI coding agents.
> Reads `DESIGN.md`, sets up theme tokens for your framework, enforces
> UI/UX quality gates on every edit, and ships a screenshot-to-code
> workflow with pixel-diff verification.
>
> **Works with:** Claude Code · Claude · Cursor · OpenAI Codex · GitHub Copilot · Gemini CLI · Google Antigravity · Windsurf · Zed · Cline · Continue.dev · Aider

---

## What it does

- **Reads `DESIGN.md`** at your project root as a *closed token layer* — the agent refuses to emit literal `#hex`, `rgb()`, `hsl()`, or unscaled `px` values in component code
- **Auto-detects your framework** (Tailwind v4 / Tailwind v3 / ShadCN / MUI / Radix Themes / Radix Primitives / Geist) and uses the matching theme adapter
- **Enforces a component state matrix** — every interactive element must define `hover`, `focus-visible`, `active`, `disabled` (plus `loading` for buttons, `error` for inputs, etc.)
- **Validates every edit via PostToolUse hooks** — hardcoded colors, off-scale px values, missing alt text, `outline: none` without replacement, layout-thrashing animations, oversized components (> 300 LOC) are flagged or blocked
- **Animation tokens** (durations + easings) with micro-interaction recipes — advanced but minimal, `prefers-reduced-motion` aware
- **Responsive patterns** with fluid clamp() typography, container queries, WCAG 2.2 touch targets, testing at 320 / 375 / 768 / 1024 / 1440 / 1920
- **Screenshot → code workflow** — a 7-pass extraction loop (layout → colors → typography → spacing → reconcile against DESIGN.md → code → visual verification)
- **Pixel-perfect verification** — `visual-diff.mjs` wraps `odiff-bin` (with `pixelmatch` fallback) and self-scores 0–100 against a reference image
- **Quality score per file** — `quality-score.sh` emits a 0–100 composite score (LOC, complexity, token usage, a11y, responsive, states, single-responsibility) with a letter grade

## Install

### Claude Code (recommended)

As a plugin via marketplace:

```bash
/plugin marketplace add VoltAgent/awesome-design-md
/plugin install awesome-design-md@awesome-design-md
```

Or install the skill directly:

```bash
# Global install (works for all projects)
bash <(curl -fsSL https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/skill/install.sh)

# Project-local install (recommended — ships hooks that auto-validate every edit)
cd /path/to/your/project
bash <(curl -fsSL https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/skill/install.sh) --project
```

### npm

```bash
# One-shot with npx
npx awesome-design-md --project

# Or install globally
npm i -g awesome-design-md
awesome-design-md --project
```

### Cursor / Codex / Copilot / Gemini / Windsurf / Cline / Continue / Aider

The install script writes a universal `AGENTS.md` at your project root plus
thin shim files for every supported agent. Every agent reads the same
design-system guidance, so you maintain one source of truth.

```bash
cd /path/to/your/project
bash <(curl -fsSL https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/skill/install.sh) --project
```

Files written:

| Agent | File |
|---|---|
| Claude Code | `.claude/skills/awesome-design-md/SKILL.md` + `.claude/settings.json` (hooks) |
| Universal | `AGENTS.md`, `DESIGN.md` |
| Claude | `CLAUDE.md` (imports AGENTS.md) |
| Cursor | `.cursor/rules/awesome-design-md.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Gemini CLI / Antigravity | `GEMINI.md` |
| Windsurf | `.windsurf/rules/design-system.md` |
| Continue.dev | `.continue/rules/design-system.md` |
| Cline | `.clinerules/design-system.md` |
| Aider / Zed / others | `AGENTS.md` (read by convention) |

For agents without native post-edit hooks (Copilot, Codex, Gemini, Continue,
Aider, Cline, Zed), the install script also writes `lefthook.yml.template`
which you can wire up as a pre-commit fallback.

### Manual install (no script)

```bash
git clone https://github.com/VoltAgent/awesome-design-md
cp -r awesome-design-md/skill/skills/awesome-design-md ~/.claude/skills/
cp awesome-design-md/skill/hooks/settings.json.template ~/.claude/settings.json
```

## Usage

After install, just ask your agent to build UI:

> "Build me a dashboard card with a stats grid and a chart placeholder"

The skill automatically:
1. Reads `DESIGN.md`
2. Detects your framework
3. Loads the matching framework adapter
4. Uses only tokens from DESIGN.md
5. Defines all required component states
6. Validates the result via hooks on every edit

### Screenshot → code

Paste a screenshot (or attach a file) and ask:

> "Recreate this screenshot using my DESIGN.md"

The skill runs the 7-pass extraction loop:

1. **Layout** — 12-col grid decomposition
2. **Color** — per-region extraction, OCR-grounded
3. **Typography** — font size/weight/tracking, snapped to scale
4. **Spacing & components** — snap to 4px/8px, identify primitives
5. **Reconcile** — diff extracted tokens against DESIGN.md, propose patch for NEW tokens (no silent inventions)
6. **Code gen** — uses ONLY reconciled tokens
7. **Visual verify** — render, screenshot, self-score, iterate up to 3 times

### Quality score

```bash
bash .claude/skills/awesome-design-md/scripts/quality-score.sh src/components/Button.tsx
# { "totalScore": 92, "grade": "A", "breakdown": { ... } }
```

### Visual diff

```bash
node .claude/skills/awesome-design-md/scripts/visual-diff.mjs reference.png actual.png diff.png 0.1
# { "pass": true, "score": 98.4, "diffPercentage": 1.6, ... }
```

## What's in the package

```
skill/
├── .claude-plugin/
│   ├── marketplace.json              # Claude Code plugin marketplace manifest
│   └── plugin.json                   # Plugin metadata
├── skills/
│   └── awesome-design-md/
│       ├── SKILL.md                  # Main skill file (Claude Code auto-loads)
│       ├── DESIGN.md                 # Enhanced template (use as blank slate)
│       ├── references/
│       │   ├── tokens-schema.md                # DTCG format + naming
│       │   ├── state-matrix.md                 # Required states + ARIA
│       │   ├── animation-tokens.md             # Durations / easings / recipes
│       │   ├── responsive-patterns.md          # Breakpoints / clamp / container queries
│       │   ├── component-quality-gates.md      # LOC / complexity / scoring rubric
│       │   ├── screenshot-to-code-workflow.md  # 7-pass extraction loop
│       │   └── framework-adapters/
│       │       ├── tailwind-v4.md
│       │       ├── tailwind-v3.md
│       │       ├── shadcn.md
│       │       ├── mui.md
│       │       ├── radix.md
│       │       └── geist.md
│       ├── scripts/
│       │   ├── install.sh                      # Main installer
│       │   ├── detect-framework.sh             # JSON detection of CSS/component stack
│       │   ├── validate-tokens.sh              # PostToolUse — token literal audit
│       │   ├── validate-component.sh           # PostToolUse — LOC/complexity/states
│       │   ├── quality-score.sh                # Composite 0–100 score
│       │   ├── inject-design-context.sh        # UserPromptSubmit hook
│       │   ├── load-design-context.sh          # SessionStart hook
│       │   └── visual-diff.mjs                 # odiff/pixelmatch wrapper
│       └── templates/
│           ├── AGENTS.md                       # Universal agent file
│           ├── settings.json.template          # Claude Code hooks
│           └── shims/
│               ├── CLAUDE.md
│               ├── GEMINI.md
│               ├── cursor-rule.mdc
│               ├── copilot-instructions.md
│               ├── windsurf-rule.md
│               ├── continue-rule.md
│               └── cline-rule.md
├── hooks/
│   ├── settings.json.template       # Claude Code hooks
│   ├── cursor-hooks.json.template   # Cursor afterFileEdit hooks
│   └── lefthook.yml.template        # pre-commit fallback for other agents
├── bin/
│   └── install.js                   # Node.js install wrapper
├── install.sh                        # Top-level bash installer
├── package.json                      # npm package
├── README.md                         # This file
└── LICENSE                           # MIT
```

## Quality gates enforced

| Gate | Warn | Hard block |
|---|---|---|
| File LOC | > 300 | > 500 |
| Function LOC | > 50 | > 80 |
| Cyclomatic complexity | > 10 | > 15 |
| JSX depth | > 4 | > 6 |
| Hooks per component | > 8 | > 12 |
| Hex literal in component | any | any |
| rgb/hsl literal in component | any | any |
| Off-scale px | any | > 3 |
| Inline `style={{ color }}` | any | any |
| Missing `alt` on `<img>` | any | any |
| `:focus` without `:focus-visible` | any | any |
| `outline: none` without replacement | any | – |
| Animating `width`/`height`/`top`/`left` | any | – |

Token files, theme configs, and `DESIGN.md` itself are exempt — they're allowed
to contain literals because they *are* the token layer.

## Score rubric (0–100)

- **LOC** (20 pts) — ≤200→20, ≤300→15, ≤500→8
- **Complexity** (20 pts) — cyclomatic ≤10 AND nested ≤8 → 20
- **Token usage** (20 pts) — 0 literals → 20, ≤2 → 10
- **A11y** (15 pts) — 0 issues → 15
- **Responsive** (10 pts) — ≥3 responsive matches → 10
- **States defined** (10 pts) — hover + focus-visible + disabled + active → 10
- **Single responsibility** (5 pts) — ≤2 exports → 5

**Grades:** 90+ A (ship) · 75–89 B (refine) · 60–74 C (block) · <60 F (rewrite)

## Uninstall

```bash
bash .claude/skills/awesome-design-md/scripts/install.sh --uninstall
```

## License

MIT © VoltAgent

## Links

- [awesome-design-md repo (this project)](https://github.com/VoltAgent/awesome-design-md)
- [Google Stitch DESIGN.md format](https://stitch.withgoogle.com/docs/design-md/overview/)
- [AGENTS.md open standard](https://agents.md/)
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills)
- [Claude Code Hooks docs](https://code.claude.com/docs/en/hooks)
- [DTCG Design Tokens spec](https://www.designtokens.org/tr/drafts/format/)
