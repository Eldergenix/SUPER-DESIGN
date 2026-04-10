# Changelog — Super Design

All notable changes to the `super-design` skill are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · [SemVer](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-04-10

Production hardening release — fixes every issue a senior designer/dev would reject.

### Added
- **`_lib.sh`** shared helper library with proper comment-stripping, true match-counting (not line-counting), accurate JSX-depth counter, JSON-field reader that works with `jq` OR `python3` OR a pure-shell fallback, path-safe file filters.
- **`lint-design-md.sh`** — validates a DESIGN.md against the required schema (sections, semantic tokens, motion tokens, forced-colors, reduced-motion guards).
- **`contrast-check.mjs`** — WCAG 2.2 AA contrast verification for every role pair in the semantic color layer. Supports hex, rgb, and OKLCH. Splits strict vs advisory pairs (decorative borders are advisory only).
- **`generate-theme.mjs`** — real codegen for Tailwind v4, ShadCN, and MUI. Reads DESIGN.md token blocks + semantic table and emits the framework-native theme file.
- **`screenshot-component.mjs`** — Playwright helper: screenshots a URL or local file with viewport control, dark mode, reduced motion, selector crop, and font-ready wait.
- **`crop-region.sh`** — crops a rectangular region from a PNG (ImageMagick → Node/sharp fallback) for focused vision-model inspection.
- **`audit.sh`** — batch style audit walker. Scores every component file under a path and sorts worst-first.
- **`test.sh`** — self-test suite with 13 assertions covering every script and both good/bad component fixtures.
- **`STATE_MATRIX.yaml`** — machine-readable component state matrix that hooks can verify against.
- **`tokens.schema.json`** — JSON Schema for DTCG tokens, including semantic layer requirements.
- **`templates/configs/.eslintrc.design-md.json`** — ship-ready ESLint config with full `jsx-a11y`, `sonarjs`, and LOC/complexity rules plus a custom no-hardcoded-color rule for inline styles.
- **`templates/configs/.stylelintrc.design-md.json`** — ship-ready Stylelint config with `color-no-hex`, declaration-value disallow lists, custom-property pattern enforcement.
- **`templates/configs/.prettierrc.design-md.json`** — Prettier with `prettier-plugin-tailwindcss` + `cva`/`cn`/`clsx` function recognition.
- **`templates/configs/playwright.design-md.config.ts`** — visual-regression config testing at every required breakpoint + dark mode + forced-colors + reduced-motion.
- **Install manifest** (`.claude/super-design.install.json`) — version tracking for migration detection.

### Changed
- **SKILL.md** rewritten as concise, scannable, imperative prose with **concrete before/after code examples** (was 1235 words of lecture; now ~1100 words of actionable specs).
- **DESIGN.md template** rewritten as a production-grade exemplar:
  - Three-layer color system (primitive → semantic → component) with **enforced semantic-over-primitive** rule
  - **OKLCH primary values with sRGB fallbacks** (wide-gamut support)
  - **Forced-colors mode** guidance (Windows High Contrast)
  - `prefers-contrast: more` support
  - **Font loading strategy** with `font-display`, preload, fallback metrics, CLS prevention
  - **Full weight scale** including the 510 signature weight
  - **Inset/stack/inline spacing** tokens (Adobe Spectrum / Carbon pattern)
  - **Logical properties** guidance (`margin-inline`, `padding-block`) for i18n/RTL
  - **Double-layer focus ring** pattern (`0 0 0 2px bg, 0 0 0 5px focus-ring`) for 3:1 contrast on any background
  - **Skeleton colors derived from surface tokens** (auto-themes)
  - **Delay tokens** (tooltip-show, hover-intent)
  - **Meta block** with `dark_mode_strategy` + `i18n.rtl_support`
- **`install.sh`** rewritten with:
  - `--dry-run` preview mode
  - Snapshot-and-rollback on failure
  - Proper `--uninstall` (removes hooks from settings.json AND shim files AND install manifest)
  - Version tracking via install manifest
  - `tar`-based copy with `.git`/`.DS_Store`/`__pycache__` exclusions (no more garbage copied)
  - Path-safe quoting throughout
  - Ships `.eslintrc`, `.stylelintrc`, `.prettierrc`, and `playwright.config` on `--project`
  - Explicit jq/python3 fallback for hook merge
- **`validate-tokens.sh`** fixed:
  - Strips `//` and `/* */` comments before scanning (no more false positives on commented hex)
  - Counts **total matches**, not matching lines
  - Proper path quoting
  - `jq`-based JSON extraction with python3/shell fallbacks
  - Detects `rgb/hsl` correctly, excluding `var()` wrappers
  - Detects primitive-token references and warns
- **`validate-component.sh`** fixed:
  - **Real JSX depth counter** (open-tag vs close-tag balance), not whitespace-divided-by-2
  - `MISSING_FOCUS_VISIBLE` is now a **violation (blocker)**, not a warning — WCAG 2.2 AA
  - Warns on missing `forced-colors` declaration
  - Warns on `async onClick` without `aria-busy`
- **`quality-score.sh`** fixed:
  - Counts **total matches**, not line counts (two hex on one line now count as 2)
  - Complexity uses cyclomatic + real JSX depth + hook count
  - Token score penalizes primitive-token references
  - A11y check looks at `<img>`/`alt=` balance, `onClick` on `div`/`span`, `:focus`-vs-`:focus-visible` balance
- **`bin/install.js`** rewritten as OS-agnostic: finds bash on macOS/Linux/Windows-Git-Bash, falls back to **pure-Node file copy + hook merge** when bash is unavailable.
- **`inject-design-context.sh`** and **`load-design-context.sh`** rewritten to use `jq`-first JSON building — no more shell variable interpolation into python (injection risk fixed).
- **Radix framework adapter** now documents all 12 scale steps with per-step semantics and generates full primitive + alpha palettes.
- **Tailwind v4 adapter** now documents both `extend` and `replace` modes (default: extend).
- **`hooks/settings.json.template`** uses `${CLAUDE_PROJECT_DIR:-$PWD}` for path portability.

### Fixed
- **`grep -c` bug** — `|| echo 0` fallback double-printed "0" when no matches, producing multi-line integers that broke arithmetic comparisons. All scripts now use `grep -oE | wc -l` for true counts.
- **Path-with-spaces bug** — `cp -R $SKILL_SRC/.` broke on any path containing spaces. Now all paths are quoted.
- **`.git`/`.DS_Store` pollution** — install was copying hidden files into the destination. `tar --exclude` strips them.
- **`grep '--text-xs'` treated flag as option** — added `-e` separator.
- **`read -d''` / `-t 0` stdin detection** — removed TTY test; arguments take precedence.
- **Contrast-check parsing of backticked values** — strips markdown inline-code backticks before parsing.

### Removed
- The `|| echo 0` anti-pattern across all scripts.
- `curl | bash` install instructions from README (security best practice).
- Shell-interpolation-into-Python strings in hooks.

## [1.0.0] — 2026-04-10

Initial release.
