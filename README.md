<div align="center">

# Super Design

**A production-grade design system skill for AI coding agents.**

Reads `DESIGN.md` as a closed token layer · Generates framework-native theme code · Enforces UI/UX quality gates on every edit via hooks · Ships with real automation, not just documentation.

[![License](https://img.shields.io/badge/license-MIT-10b981?style=flat-square)](./LICENSE)
[![Version](https://img.shields.io/badge/version-1.1.0-7170ff?style=flat-square)](./skill/CHANGELOG.md)
[![Tests](https://img.shields.io/badge/tests-13%2F13%20passing-10b981?style=flat-square)](./skill/skills/super-design/scripts/test.sh)
[![Skill Format](https://img.shields.io/badge/SKILL.md-1.0-5e6ad2?style=flat-square)](https://code.claude.com/docs/en/skills)

</div>

---

## What is Super Design?

Super Design is an installable **AI skill** that teaches any modern AI coding agent (Claude Code, Cursor, Codex, Copilot, Gemini, Windsurf, Cline, Continue, Antigravity, Aider, Zed) how to build and maintain production-grade UI. It is the **closed token layer + quality gate layer** that sits between your brand and the code an AI writes.

It is NOT a component library. You bring your own React/Vue/Svelte stack. Super Design ensures that whatever the AI writes references your `DESIGN.md` tokens, covers every interactive state, meets WCAG 2.2 AA, works at every viewport, and ships under 300 LOC per component.

```
Your brand → DESIGN.md → Super Design skill → AI writes correct UI code
                              ↓
                  PostToolUse hooks validate on every edit
                  (block hardcoded colors, off-scale px,
                   missing focus-visible, a11y violations, etc.)
```

## Install (one line)

**Claude Code (plugin marketplace):**
```
/plugin marketplace add Eldergenix/SUPER-DESIGN
/plugin install super-design@super-design
```

**Any AI agent (git clone + bash):**
```bash
git clone https://github.com/Eldergenix/SUPER-DESIGN.git /tmp/super-design
cd /path/to/your/project
bash /tmp/super-design/skill/install.sh --project --dry-run   # preview
bash /tmp/super-design/skill/install.sh --project             # install
```

**npm / npx (cross-platform, Windows-friendly):**
```bash
npx super-design --project
```

Uninstall cleanly: `bash .claude/skills/super-design/scripts/install.sh --uninstall`

See [`skill/README.md`](./skill/README.md) for the full installer documentation, flags, and troubleshooting.

## What you get

| Capability | How |
|---|---|
| **Closed token layer** enforced on every edit | `DESIGN.md` + PostToolUse hooks |
| **Framework theme codegen** — Tailwind v4, ShadCN, MUI | `scripts/generate-theme.mjs` |
| **WCAG 2.2 AA contrast verification** for every semantic color pair | `scripts/contrast-check.mjs` (OKLCH + sRGB) |
| **DESIGN.md schema validation** | `scripts/lint-design-md.sh` |
| **Block hardcoded colors / off-scale px / missing alt / `:focus` without `:focus-visible`** | `scripts/validate-tokens.sh` |
| **Block components > 500 LOC, JSX depth > 6, missing state coverage** | `scripts/validate-component.sh` |
| **0–100 composite quality score** with letter grade | `scripts/quality-score.sh` |
| **Batch audit** that sorts worst-first | `scripts/audit.sh` |
| **Screenshot → code** with 7-pass extraction workflow | `references/screenshot-to-code-workflow.md` + `scripts/crop-region.sh` + `scripts/screenshot-component.mjs` |
| **Visual regression** with pixel-diff self-scoring | `scripts/visual-diff.mjs` (odiff + pixelmatch) |
| **Cross-agent shim files** — one install, every agent picks up the same guidance | Auto-written on `--project` install |
| **Self-test suite** — 13 tests on good/bad fixtures | `scripts/test.sh` |

## Repository layout

```
SUPER-DESIGN/
├── README.md                        # This file
├── LICENSE                          # MIT
├── CONTRIBUTING.md                  # Contribution guidelines for the design-md collection
├── skill/                           # ← The installable Super Design skill
│   ├── README.md                    #   Full skill documentation
│   ├── CHANGELOG.md                 #   Version history
│   ├── CONTRIBUTING.md              #   How to extend the skill
│   ├── install.sh                   #   Bash installer (macOS / Linux / Git Bash)
│   ├── bin/install.js               #   Cross-platform Node installer
│   ├── package.json                 #   npm package
│   ├── .claude-plugin/              #   Claude Code plugin manifests
│   ├── hooks/                       #   Hook templates (Claude settings.json, Cursor, lefthook)
│   └── skills/super-design/         #   SKILL.md + DESIGN.md + references + scripts
│       ├── SKILL.md                 #     Agent-facing skill instructions
│       ├── DESIGN.md                #     Enhanced DESIGN.md template (OKLCH, forced-colors, i18n)
│       ├── references/              #     Progressive-disclosure reference docs
│       │   ├── framework-adapters/  #       tailwind-v4, tailwind-v3, shadcn, mui, radix, geist
│       │   ├── state-matrix.md      #       Required states per component
│       │   ├── STATE_MATRIX.yaml    #       Machine-readable state matrix
│       │   ├── tokens.schema.json   #       DTCG JSON Schema
│       │   ├── animation-tokens.md
│       │   ├── responsive-patterns.md
│       │   ├── component-quality-gates.md
│       │   └── screenshot-to-code-workflow.md
│       ├── scripts/                 #     All 14 automation scripts
│       └── templates/               #     AGENTS.md, CLAUDE.md, shims, ESLint/Stylelint/Prettier configs
└── design-md/                       # ← Curated DESIGN.md collection (55 real brands)
    ├── linear.app/                  #   Each folder: DESIGN.md + README + preview.html + preview-dark.html
    ├── stripe/
    ├── vercel/
    ├── apple/
    └── ... (55 total)
```

## The DESIGN.md collection

Alongside the skill, this repo ships **55 production-extracted `DESIGN.md` files** from real developer-facing websites. Use any of them as a reference implementation of the format, or copy one directly into your project as a starting point:

### AI & Machine Learning
[Claude](./design-md/claude/) · [Cohere](./design-md/cohere/) · [ElevenLabs](./design-md/elevenlabs/) · [Minimax](./design-md/minimax/) · [Mistral AI](./design-md/mistral.ai/) · [Ollama](./design-md/ollama/) · [OpenCode AI](./design-md/opencode.ai/) · [Replicate](./design-md/replicate/) · [RunwayML](./design-md/runwayml/) · [Together AI](./design-md/together.ai/) · [VoltAgent](./design-md/voltagent/) · [xAI](./design-md/x.ai/)

### Developer Tools & Platforms
[Cursor](./design-md/cursor/) · [Expo](./design-md/expo/) · [Linear](./design-md/linear.app/) · [Lovable](./design-md/lovable/) · [Mintlify](./design-md/mintlify/) · [PostHog](./design-md/posthog/) · [Raycast](./design-md/raycast/) · [Resend](./design-md/resend/) · [Sentry](./design-md/sentry/) · [Supabase](./design-md/supabase/) · [Superhuman](./design-md/superhuman/) · [Vercel](./design-md/vercel/) · [Warp](./design-md/warp/) · [Zapier](./design-md/zapier/)

### Infrastructure & Cloud
[ClickHouse](./design-md/clickhouse/) · [Composio](./design-md/composio/) · [HashiCorp](./design-md/hashicorp/) · [MongoDB](./design-md/mongodb/) · [Sanity](./design-md/sanity/) · [Stripe](./design-md/stripe/)

### Design & Productivity
[Airtable](./design-md/airtable/) · [Cal.com](./design-md/cal/) · [Clay](./design-md/clay/) · [Figma](./design-md/figma/) · [Framer](./design-md/framer/) · [Intercom](./design-md/intercom/) · [Miro](./design-md/miro/) · [Notion](./design-md/notion/) · [Pinterest](./design-md/pinterest/) · [Webflow](./design-md/webflow/)

### Fintech & Crypto
[Coinbase](./design-md/coinbase/) · [Kraken](./design-md/kraken/) · [Revolut](./design-md/revolut/) · [Wise](./design-md/wise/)

### Enterprise & Consumer
[Airbnb](./design-md/airbnb/) · [Apple](./design-md/apple/) · [BMW](./design-md/bmw/) · [IBM](./design-md/ibm/) · [NVIDIA](./design-md/nvidia/) · [SpaceX](./design-md/spacex/) · [Spotify](./design-md/spotify/) · [Uber](./design-md/uber/)

## Why "Super Design"?

Existing AI coding agents reliably produce **plausible** UI that looks OK in isolation and falls apart the moment you audit it: hardcoded colors scattered across files, missing focus rings, skipped disabled states, 800-line components, `style={{ color: '#fff' }}` inline everywhere, no forced-colors fallback, animation on `width`/`height`.

Super Design fixes this by treating the design system as a **contract the AI cannot silently break**. Every edit runs through a PostToolUse hook. Every color references a semantic token. Every interactive element has focus-visible, active, disabled, loading states. Every file stays under 300 LOC. Every layout passes at 320/375/768/1024/1440/1920. Every color pair meets WCAG 2.2 AA. If the AI tries to skip any of it, the hook blocks the edit with a clear violation message.

It is the layer that makes AI-generated UI actually ship-ready.

## Compatibility

Super Design installs as a Claude Code skill AND drops a matching shim file for every other agent, so one install covers:

| Agent | Picks up via |
|---|---|
| **Claude Code** | `.claude/skills/super-design/SKILL.md` + `.claude/settings.json` hooks |
| **Cursor** | `.cursor/rules/super-design.mdc` |
| **GitHub Copilot** | `.github/copilot-instructions.md` |
| **OpenAI Codex CLI / ChatGPT Codex** | `AGENTS.md` |
| **Gemini CLI / Google Antigravity** | `GEMINI.md` (+ `AGENTS.md`) |
| **Windsurf** | `.windsurf/rules/design-system.md` |
| **Zed** | `AGENTS.md` (native) |
| **Cline** | `.clinerules/design-system.md` |
| **Continue.dev** | `.continue/rules/design-system.md` |
| **Aider** | `CONVENTIONS.md` via `.aider.conf.yml` |

All shims reference the same single source of truth (`AGENTS.md` + `DESIGN.md`), so your design system never drifts across agents.

## Requesting a DESIGN.md

Want a DESIGN.md extracted from a specific website? [Open a GitHub issue](https://github.com/Eldergenix/SUPER-DESIGN/issues/new?template=design-md-request.yml).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the DESIGN.md collection, and [`skill/CONTRIBUTING.md`](./skill/CONTRIBUTING.md) for extending the Super Design skill itself.

## License

MIT — see [LICENSE](./LICENSE). All `DESIGN.md` files in `design-md/` represent publicly visible CSS values extracted from live websites; we do not claim ownership of any site's visual identity.

## Links

- [Skill documentation (`skill/README.md`)](./skill/README.md)
- [Skill changelog](./skill/CHANGELOG.md)
- [Google Stitch DESIGN.md format](https://stitch.withgoogle.com/docs/design-md/overview/)
- [AGENTS.md open standard](https://agents.md/)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks)
- [DTCG Design Tokens spec](https://www.designtokens.org/tr/drafts/format/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
