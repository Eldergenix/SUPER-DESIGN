# Contributing to Awesome Design MD

Thanks for contributing.

This repository is a curated collection of DESIGN.md files extracted from popular websites. Each file captures a site's complete visual language in a format any AI agent can read.

## How to Contribute

### Request a New Site

The easiest way to contribute. [Open an issue](https://github.com/VoltAgent/awesome-design-md/issues) with:

- The site URL
- Why it's interesting (unique design language, popular brand, etc.)

We'll extract the DESIGN.md and add it to the collection.

### Improve an Existing DESIGN.md

If you notice issues with an existing file:

1. Open the site's `DESIGN.md`
2. Compare against the live site
3. Fix incorrect hex values, missing tokens, or weak descriptions
4. Update the `preview.html` and `preview-dark.html` if your changes affect displayed tokens
5. Open a PR with before/after rationale

### Submit a New DESIGN.md

If you've extracted a DESIGN.md yourself:

1. Create a directory named after the site (e.g., `x/`)
2. Include at minimum:
   - `DESIGN.md`: The design system document
   - `preview.html`: Visual catalog (light)
   - `preview-dark.html`: Visual catalog (dark)
3. Update `README.md`: Add the site to the correct category table
4. Open a PR with the site name and a short description

## DESIGN.md Quality Bar

Every DESIGN.md must include all 9 sections:

1. Visual Theme & Atmosphere
2. Color Palette & Roles
3. Typography Rules
4. Component Stylings
5. Layout Principles
6. Depth & Elevation
7. Do's and Don'ts
8. Responsive Behavior
9. Agent Prompt Guide

### Writing Standards

- **Every color**: Semantic Name (`#hex`) + functional role
- **Atmosphere**: Evocative and specific, never "clean and modern"
- **Typography**: Full hierarchy table with size, weight, line-height, letter-spacing
- **Components**: Include hover/focus states and transition timing
- **Why, not just what**: Explain the reasoning behind design decisions

### Common Issues to Watch For

- Hex values that don't match the live site (token extraction isn't perfect)
- Missing hover/focus states on buttons and links
- Generic atmosphere descriptions that could apply to any site
- Incomplete typography tables (missing code font, small labels, etc.)

## Preview HTML Standards

- Self-contained single HTML file (inline CSS, no external dependencies except Google Fonts)
- Must display: color swatches, typography scale, button variants, card examples, form elements, spacing scale, border radius, elevation levels
- No logo icons or emoji icons in the nav. Plain text site name only
- No Do's and Don'ts section in the HTML preview
- Responsive: must look reasonable on mobile

## Validation Checklist (Before PR)

- [ ] All 9 sections present in DESIGN.md
- [ ] Every color has semantic name + hex + role
- [ ] Typography table is complete with real values
- [ ] Preview HTML files are self-contained and render correctly
- [ ] Site added to correct category in README.md
- [ ] Links in README resolve correctly

## Pull Request Checklist

- [ ] Added/updated DESIGN.md file
- [ ] Added/updated preview HTML files
- [ ] Updated main README.md
- [ ] Included clear PR description
- [ ] Verified against live site

## Style Notes

- Keep documentation in English.
- Prefer precise, descriptive wording over marketing language.
- Keep category descriptions short and factual.
- Alphabetical ordering within categories.

## License

By contributing, you agree your contributions are provided under the repository license terms.
