<div align="center">

# Awesome Design MD

**Curated collection of DESIGN.md files inspired by popular websites.**

Copy a DESIGN.md into your project, tell your AI agent "build me a page that looks like this" and get pixel-perfect UI that actually matches.


<br />

[![Awesome](https://awesome.re/badge.svg)](https://awesome.re)
![Site Count](https://img.shields.io/badge/sites-3-10b981?style=classic)
[![Last Update](https://img.shields.io/github/last-commit/VoltAgent/awesome-design-md?label=Last%20update&style=classic)](https://github.com/VoltAgent/awesome-design-md)
[![Discord](https://img.shields.io/discord/1361559153780195478.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://s.voltagent.dev/discord)


</div>

<br />

## What is DESIGN.md?

[DESIGN.md](https://stitch.withgoogle.com/docs/design-md/overview/) is a concept introduced by Google Stitch. A plain-text design system document that AI agents read to generate consistent UI.

It's just a markdown file. You can read it, edit it, commit it to git. No Figma exports, no JSON schemas, no special tooling. Drop it into your project root and any AI coding agent instantly understands how your UI should look. Markdown is the format LLMs read best, so there's nothing to parse or configure.

| File | Who reads it | What it defines |
|------|-------------|-----------------|
| `AGENTS.md` | Coding agents | How to build the project |
| `DESIGN.md` | Design agents | How the project should look and feel |

**This repo provides ready-to-use DESIGN.md files** extracted from real websites. 



## What's Inside Each DESIGN.md

Every file follows the [Stitch DESIGN.md format](https://stitch.withgoogle.com/docs/design-md/format/) with extended sections:

| # | Section | What it captures |
|---|---------|-----------------|
| 1 | Visual Theme & Atmosphere | Mood, density, design philosophy |
| 2 | Color Palette & Roles | Semantic name + hex + functional role |
| 3 | Typography Rules | Font families, full hierarchy table |
| 4 | Component Stylings | Buttons, cards, inputs, navigation with states |
| 5 | Layout Principles | Spacing scale, grid, whitespace philosophy |
| 6 | Depth & Elevation | Shadow system, surface hierarchy |
| 7 | Do's and Don'ts | Design guardrails and anti-patterns |
| 8 | Responsive Behavior | Breakpoints, touch targets, collapsing strategy |
| 9 | Agent Prompt Guide | Quick color reference, ready-to-use prompts |

Each site includes:

| File | Purpose |
|------|---------|
| `DESIGN.md` | The design system (what agents read) |
| `preview.html` | Visual catalog showing color swatches, type scale, buttons, cards |
| `preview-dark.html` | Same catalog with dark surfaces |

### How to Use


1. Copy a site's `DESIGN.md` into your project root
2. Tell your AI agent to use it.

## Collection

### Developer Tools & Platforms

Sites building tools for developers. Dark themes, code-first aesthetics, terminal vibes.

| Site | Description | Preview |
|------|-------------|---------|
| [**Cloudflare**](cloudflare/DESIGN.md) | Bold orange identity, high-contrast sections, billboard-scale typography | [Light](cloudflare/preview.html) · [Dark](cloudflare/preview-dark.html) |
| [**VoltAgent**](voltagent/DESIGN.md) | Void-black canvas, emerald "voltage" accent, terminal-native aesthetic | [Light](voltagent/preview.html) · [Dark](voltagent/preview-dark.html) |

### Product & SaaS

Consumer-facing product sites with polished, conversion-focused design.

| Site | Description | Preview |
|------|-------------|---------|
| [**Expo**](expo/DESIGN.md) | Dark developer platform, tight letter-spacing, code-centric hero | [Light](expo/preview.html) · [Dark](expo/preview-dark.html) |

---

> **Want a specific site added?** [Open an issue](https://github.com/VoltAgent/awesome-design-md/issues) with the URL.



## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- [**Request a site**](https://github.com/VoltAgent/awesome-design-md/issues): Open an issue with the URL
- **Improve existing files**: Fix wrong colors, missing tokens, weak descriptions
- **Report issues**: Let us know if something looks off






## License

MIT License - see [LICENSE](LICENSE)

This repository is a curated collection of design system documents extracted from public websites. All DESIGN.md files are provided "as is" without warranty. The extracted design tokens represent publicly visible CSS values. We do not claim ownership of any site's visual identity. These documents exist to help AI agents generate consistent UI.
