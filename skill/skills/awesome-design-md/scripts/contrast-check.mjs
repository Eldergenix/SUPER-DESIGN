#!/usr/bin/env node
/**
 * contrast-check.mjs — WCAG 2.2 contrast verification for DESIGN.md tokens.
 *
 * Reads a DESIGN.md file, extracts the semantic color layer, and asserts
 * that every role pair meets the required contrast ratio.
 *
 * Usage:
 *   node contrast-check.mjs DESIGN.md
 *
 * Exit 0 if all pairs pass, 1 if any fail.
 *
 * Implements the WCAG 2.x relative luminance formula (not APCA — APCA is
 * not yet normative). OKLCH and hex are both supported.
 */

import fs from 'node:fs';
import path from 'node:path';

const filePath = process.argv[2] || 'DESIGN.md';
if (!fs.existsSync(filePath)) {
  console.error(`[design-md] file not found: ${filePath}`);
  process.exit(2);
}

const content = fs.readFileSync(filePath, 'utf8');

// ------------------------------------------------------------------
// Color parsing — hex, rgb(), oklch() (approximate)
// ------------------------------------------------------------------

function hexToRgb(hex) {
  hex = hex.replace('#', '');
  if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
  if (hex.length === 8) hex = hex.slice(0, 6);
  const int = parseInt(hex, 16);
  return { r: (int >> 16) & 255, g: (int >> 8) & 255, b: int & 255 };
}

function rgbStringToRgb(str) {
  const m = str.match(/rgba?\s*\(\s*([0-9.]+)[ ,]+([0-9.]+)[ ,]+([0-9.]+)/);
  if (!m) return null;
  return { r: +m[1], g: +m[2], b: +m[3] };
}

/**
 * OKLCH → sRGB. Uses the Oklab → linear sRGB → gamma-encoded sRGB pipeline.
 * OKLCH format: oklch(L% C H)  where L = 0..1 (or 0..100%), C = 0..~0.4, H = degrees.
 */
function oklchStringToRgb(str) {
  const m = str.match(/oklch\s*\(\s*([0-9.]+)%?\s+([0-9.]+)\s+([0-9.]+)(?:deg)?/i);
  if (!m) return null;
  let L = parseFloat(m[1]);
  if (L > 1) L /= 100; // handle "98.5%" as well as "0.985"
  const C = parseFloat(m[2]);
  const Hdeg = parseFloat(m[3]);

  const a = C * Math.cos((Hdeg * Math.PI) / 180);
  const b = C * Math.sin((Hdeg * Math.PI) / 180);

  // Oklab → linear sRGB
  const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = L - 0.0894841775 * a - 1.2914855480 * b;

  const l3 = l_ ** 3;
  const m3 = m_ ** 3;
  const s3 = s_ ** 3;

  const lr =  4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  const lg = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  const lb = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  const toSrgb = (u) => {
    const c = Math.max(0, Math.min(1, u));
    return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
  };

  return {
    r: Math.round(toSrgb(lr) * 255),
    g: Math.round(toSrgb(lg) * 255),
    b: Math.round(toSrgb(lb) * 255),
  };
}

function parseColor(str) {
  str = str.trim().replace(/`/g, '').replace(/^"|"$/g, '');
  if (str.startsWith('#')) return hexToRgb(str);
  if (str.startsWith('oklch')) return oklchStringToRgb(str);
  if (str.startsWith('rgb')) return rgbStringToRgb(str);
  return null;
}

// ------------------------------------------------------------------
// WCAG 2.x luminance + contrast
// ------------------------------------------------------------------

function luminance({ r, g, b }) {
  const norm = (v) => {
    v /= 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * norm(r) + 0.7152 * norm(g) + 0.0722 * norm(b);
}

function contrast(fg, bg) {
  const L1 = luminance(fg);
  const L2 = luminance(bg);
  const [light, dark] = L1 > L2 ? [L1, L2] : [L2, L1];
  return (light + 0.05) / (dark + 0.05);
}

// ------------------------------------------------------------------
// Extract tokens from DESIGN.md
// ------------------------------------------------------------------

function extractSemanticTable(md) {
  // Find lines that look like: | `--color-x` | value | value | role | contrast |
  const tokens = { light: {}, dark: {} };
  const lines = md.split('\n');
  let inTable = false;
  for (const line of lines) {
    if (/\|\s*Token\s*\|\s*Light\s*\|\s*Dark\s*\|/i.test(line)) {
      inTable = true;
      continue;
    }
    if (inTable && /^\|[-\s:|]+\|$/.test(line)) continue;
    if (inTable && !line.trim().startsWith('|')) { inTable = false; continue; }
    if (inTable) {
      const cells = line.split('|').map(c => c.trim());
      if (cells.length < 5) continue;
      const name = cells[1].replace(/`/g, '').replace(/\\/g, '');
      const light = cells[2];
      const dark = cells[3];
      if (name.startsWith('--color-')) {
        tokens.light[name] = light;
        tokens.dark[name] = dark;
      }
    }
  }
  return tokens;
}

// ------------------------------------------------------------------
// Extract primitive tokens so we can resolve aliases like {color.neutral.50}
// ------------------------------------------------------------------

function extractPrimitives(md) {
  const prims = {};
  const blockRe = /```tokens\s+color\.([\w.-]+)\n([\s\S]*?)```/g;
  let blockMatch;
  while ((blockMatch = blockRe.exec(md)) !== null) {
    const group = blockMatch[1];
    const body = blockMatch[2];
    for (const entry of body.split('\n')) {
      const m = entry.match(/^-\s+([\w-]+)\s*\(color\):\s*(\S+.*?)(\s*#.*)?$/);
      if (!m) continue;
      prims[`color.${group}.${m[1]}`] = m[2].trim();
    }
  }
  return prims;
}

function resolveAlias(val, prims) {
  if (!val) return null;
  const m = val.match(/\{([\w.-]+)\}/);
  if (m) {
    const resolved = prims[m[1]];
    if (resolved) return resolved;
    return null;
  }
  return val;
}

// ------------------------------------------------------------------
// Define the required contrast pairs (WCAG 2.2 AA)
// ------------------------------------------------------------------

// WCAG 2.2 required contrast pairs.
//
// Text pairs must meet 4.5:1 (AA normal) or 3:1 (AA large). UI-boundary pairs
// (focus rings, accent links, border-strong) must meet 3:1 per SC 1.4.11.
//
// The decorative `--color-border` is INTENTIONALLY not in the strict list:
// real design systems (Linear, Stripe, Vercel) use near-invisible borders
// PLUS elevation/shadow for component separation. The strict boundary check
// applies to `--color-border-strong`, which IS the sole indicator when used.
const CONTRAST_PAIRS = [
  { fg: '--color-fg',            bg: '--color-bg',       min: 4.5, label: 'Body text on page bg' },
  { fg: '--color-fg',            bg: '--color-surface',  min: 4.5, label: 'Body text on card surface' },
  { fg: '--color-fg-muted',      bg: '--color-bg',       min: 4.5, label: 'Muted text on page bg' },
  { fg: '--color-fg-muted',      bg: '--color-surface',  min: 4.5, label: 'Muted text on card surface' },
  { fg: '--color-fg-on-accent',  bg: '--color-accent',   min: 4.5, label: 'Text on accent button' },
  { fg: '--color-focus-ring',    bg: '--color-bg',       min: 3.0, label: 'Focus ring vs bg' },
  { fg: '--color-focus-ring',    bg: '--color-surface',  min: 3.0, label: 'Focus ring vs surface' },
  { fg: '--color-border-strong', bg: '--color-surface',  min: 3.0, label: 'Strong border vs surface (UI boundary)' },
  { fg: '--color-accent',        bg: '--color-bg',       min: 3.0, label: 'Accent link vs page bg' },
];

// Advisory pairs — warn if below 1.5:1 (invisible), never block
const ADVISORY_PAIRS = [
  { fg: '--color-border',        bg: '--color-surface',  min: 1.5, label: 'Decorative border vs surface (visibility)' },
];

// ------------------------------------------------------------------
// Run
// ------------------------------------------------------------------

const primitives = extractPrimitives(content);
const semantic = extractSemanticTable(content);

const modes = Object.keys(semantic).filter(m => Object.keys(semantic[m]).length > 0);

if (modes.length === 0) {
  console.error('[design-md] could not extract semantic color table — ensure section 2.2 uses the standard `| Token | Light | Dark |` format');
  process.exit(2);
}

const report = { passed: [], failed: [], advisory: [], skipped: [] };

function evalPair(mode, pair, advisory = false) {
  const tokens = semantic[mode];
  const fgRaw = resolveAlias(tokens[pair.fg], primitives);
  const bgRaw = resolveAlias(tokens[pair.bg], primitives);

  if (!fgRaw || !bgRaw) {
    report.skipped.push({ mode, ...pair, reason: `unresolved: fg=${tokens[pair.fg]}, bg=${tokens[pair.bg]}` });
    return;
  }
  const fgColor = parseColor(fgRaw);
  const bgColor = parseColor(bgRaw);
  if (!fgColor || !bgColor) {
    report.skipped.push({ mode, ...pair, reason: `unparseable: fg=${fgRaw}, bg=${bgRaw}` });
    return;
  }
  const ratio = contrast(fgColor, bgColor);
  const pass = ratio >= pair.min;
  const record = {
    mode,
    fg: pair.fg,
    bg: pair.bg,
    fgValue: fgRaw,
    bgValue: bgRaw,
    ratio: Number(ratio.toFixed(2)),
    required: pair.min,
    label: pair.label,
  };
  if (advisory) {
    if (!pass) report.advisory.push(record);
    else report.passed.push(record);
  } else {
    if (pass) report.passed.push(record);
    else report.failed.push(record);
  }
}

for (const mode of modes) {
  for (const pair of CONTRAST_PAIRS)  evalPair(mode, pair, false);
  for (const pair of ADVISORY_PAIRS)  evalPair(mode, pair, true);
}

console.log(JSON.stringify(report, null, 2));

if (report.failed.length > 0) {
  console.error(`\n❌ ${report.failed.length} WCAG 2.2 AA contrast failure(s):`);
  for (const f of report.failed) {
    console.error(`  • [${f.mode}] ${f.label}: ${f.ratio}:1 (need ${f.required}:1)  — ${f.fg} on ${f.bg}`);
  }
}

if (report.advisory.length > 0) {
  console.warn(`\n⚠ ${report.advisory.length} advisory note(s):`);
  for (const a of report.advisory) {
    console.warn(`  • [${a.mode}] ${a.label}: ${a.ratio}:1 (advisory min ${a.required}:1) — ${a.fg} on ${a.bg}`);
  }
}

if (report.skipped.length > 0) {
  console.warn(`\n⚠ ${report.skipped.length} pair(s) skipped (could not resolve tokens):`);
  for (const s of report.skipped) {
    console.warn(`  • [${s.mode}] ${s.label}: ${s.reason}`);
  }
}

if (report.failed.length === 0) {
  console.log(`\n✓ ${report.passed.length} contrast pair(s) pass WCAG 2.2 AA`);
  process.exit(0);
}
process.exit(1);
