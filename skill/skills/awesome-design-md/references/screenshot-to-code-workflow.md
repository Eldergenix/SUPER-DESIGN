# Screenshot → Code: 7-Pass Extraction Loop

When the user provides a screenshot to recreate, follow this workflow exactly. Each pass has a specific objective, a measurable artifact, and a confidence score.

## Guiding principles

1. **Never skip the reconcile pass.** Extracted tokens must be diffed against the project's existing `DESIGN.md`. Never silently invent tokens.
2. **OCR-ground typography.** Never let the model guess text content — read the actual pixels.
3. **Crop and zoom.** For dense regions, crop the screenshot and re-prompt. Crops produce substantially better vision-model accuracy than one-shot full-frame analysis.
4. **Layout JSON is a constraint.** Feed Pass 1's region tree back as a constraint in every subsequent pass to prevent drift.
5. **Self-score and loop.** Render → screenshot → diff → critique → refine. Cap at 3 iterations; Self-Refine plateaus after ~3.

## Pass 1 — Layout skeleton

**Objective:** Structural decomposition only, no styling.

**Prompt template:**
> "Ignore all colors and typography. Overlay a mental 12-column grid on this screenshot. Identify separation lines first (horizontal then vertical, DCGen-style). Return JSON:
>
> ```json
> {
>   "regions": [
>     {
>       "id": "r1",
>       "role": "header | nav | hero | sidebar | card | grid | list | footer",
>       "gridCol": [1, 13],
>       "gridRow": [1, 2],
>       "children": ["r2", "r3"],
>       "confidence": 0.92
>     }
>   ]
> }
> ```
>
> Report any region where your confidence is below 0.7 as a follow-up crop request."

**Measure:** region count, nesting depth, grid-column alignment consistency.

## Pass 2 — Color extraction

**Objective:** Per-region colors, grounded in real pixels.

**Prompt template:**
> "For each region from Pass 1, report the dominant background hex, foreground text hex, and any accent hex. Use OCR on visible text to ground yourself — read the actual pixels near that text. Return:
>
> ```json
> {
>   "regionColors": [
>     { "regionId": "r1", "bg": "#0a0a0a", "fg": "#f7f8f8", "accent": "#5e6ad2" }
>   ],
>   "palette": [
>     { "hex": "#0a0a0a", "frequencyRank": 1, "roleGuess": "page-bg" },
>     { "hex": "#f7f8f8", "frequencyRank": 2, "roleGuess": "primary-text" }
>   ]
> }
> ```"

**Measure:** ΔE2000 delta vs reference (target < 5 per color), palette coverage ≥ 95% of pixels.

## Pass 3 — Typography

**Objective:** Extract fonts, sizes, weights, tracking.

**Prompt template:**
> "For each text run you OCR'd in Pass 2, estimate:
>
> ```json
> {
>   "textRuns": [
>     {
>       "text": "Start building",
>       "fontFamilyGuess": "Inter",
>       "fontSizePx": 48,
>       "fontWeight": 600,
>       "lineHeightPx": 52,
>       "letterSpacingPx": -1.056,
>       "textAlign": "center",
>       "regionId": "r2"
>     }
>   ]
> }
> ```
>
> Snap sizes to the nearest 2px. Identify at most 5 type styles (display, h1, h2, body, caption) and map every text run to one of them."

**Measure:** Size histogram collapses to ≤ 5 buckets. Weight values in {400, 500, 510, 600, 700}.

## Pass 4 — Spacing & components

**Objective:** Extract padding / gap values and identify component primitives.

**Prompt template:**
> "Measure the padding and gaps in every region. Snap every value to the nearest multiple of 4px (then try 8px) and report which base unit fits best. Identify reusable components (button, input, card, badge, avatar, nav-item, dropdown) and return:
>
> ```json
> {
>   "baseUnit": 4,
>   "regionSpacing": [
>     { "regionId": "r2", "paddingX": 24, "paddingY": 16, "gap": 12 }
>   ],
>   "components": [
>     { "type": "button", "variant": "primary", "regionIds": ["r4"] }
>   ]
> }
> ```
>
> Use shadcn/ui vocabulary where possible. If the framework is Tailwind, also give the matching class names."

**Measure:** ≥ 90% of spacing values fit a single base unit (4px or 8px).

## Pass 5 — Reconcile against DESIGN.md

**Objective:** Diff extracted tokens against existing `DESIGN.md`. Classify each as `EXACT_MATCH`, `NEAR_MATCH`, or `NEW`. Propose a diff-style patch for `DESIGN.md` for any NEW tokens. **Get user approval before adding.**

**Prompt template:**
> "Here are extracted tokens from Passes 2–4:
>
> ```json
> { extracted }
> ```
>
> Here is the project's existing DESIGN.md:
>
> ```md
> { designMdContents }
> ```
>
> For each extracted token, classify as:
> - `EXACT_MATCH` — already defined with the same value; REUSE
> - `NEAR_MATCH` — existing token within ΔE < 5 (color) or ±2px (spacing); REUSE the existing one
> - `NEW` — genuinely new, propose addition with justification
>
> Output a diff-style patch:
>
> ```diff
> ## 2.1 Primitive tokens
> + color.indigo.550: #5e6ad2  (extracted from hero CTA; no existing match within ΔE 5)
> ```
>
> NEVER silently invent tokens. Wait for user approval before writing the patch to DESIGN.md."

**Measure:** Number of NEW tokens. High counts indicate drift — the target is ≤ 3 new tokens per screenshot.

## Pass 6 — Code generation

**Objective:** Generate component code using ONLY reconciled tokens.

**Prompt template:**
> "Using ONLY tokens from the reconciled DESIGN.md (below), generate the component. Reference tokens by NAME (`bg-surface`, `var(--color-accent)`), never by literal value. Follow the Pass-1 layout tree exactly. Use the framework adapter appropriate for this project (detected: {framework}). Use shadcn/ui primitives for components identified in Pass 4 where available.
>
> Constraints:
> - Max 300 LOC per file
> - Every interactive element defines hover, focus-visible, active, disabled
> - `:focus-visible` not `:focus`
> - Respect `prefers-reduced-motion`
> - Min 44×44 touch targets
> - Container queries for reusable layouts
>
> DESIGN.md:
> ```md
> { designMdContents }
> ```"

## Pass 7 — Visual verification (self-scoring)

**Objective:** Render the output, screenshot it, diff against the reference, self-score.

**Shell:**
```bash
node ${CLAUDE_SKILL_DIR}/scripts/visual-diff.mjs reference.png actual.png diff.png 0.1
```

**Prompt template:**
> "Reference image is A, my rendered output is B. The pixel diff JSON is:
>
> ```json
> { diffJson }
> ```
>
> Score 0–10 on each axis and cite specific regionIds where you lose points:
>
> 1. Layout fidelity (bbox alignment, ordering, nesting)
> 2. Color fidelity (per-region ΔE)
> 3. Typography (size, weight, family feel)
> 4. Spacing rhythm (gap/padding consistency)
> 5. Component identity (right primitives used)
>
> Return:
>
> ```json
> {
>   "scores": { "layout": 9, "color": 8, "type": 7, "spacing": 9, "components": 9 },
>   "overallScore": 8.4,
>   "topThreeFixes": [
>     { "regionId": "r4", "issue": "button padding 12px not 16px", "proposedPatch": "px-4 → px-5" }
>   ]
> }
> ```
>
> If overallScore < 8.5, emit a refined code patch and loop."

## Loop rules

- Loop Passes 6 → 7 up to **3 iterations** or until `overallScore ≥ 8.5` (or `pixelScore ≥ 95`)
- If still failing after 3 iterations: surface the remaining deltas to the user with specific crops and ask for guidance
- Never loop > 5 times — improvements plateau, compute cost rises

## Measurable artifacts per pass

| Artifact | Target |
|---|---|
| BBox IoU per region | > 0.85 |
| ΔE2000 per color token | < 5 |
| Font-size MAE (pixels) | < 2 |
| Spacing base-unit fit | > 90% |
| Overall SSIM (rendered vs reference) | > 0.9 |
| Pixel similarity score (100 - diffPct) | ≥ 95 |

## Key implementation notes

- **Crop tool uplift:** give the model per-region crops for complex sections, not just the full frame
- **OCR grounding:** always read the actual text pixels for typography; never guess
- **Never skip Pass 5:** it's what prevents token proliferation and keeps outputs on-system
- **Constraint propagation:** feed Pass 1's JSON back into every later pass
- **Separation-line first:** DCGen's divide-and-conquer beats monolithic generation
