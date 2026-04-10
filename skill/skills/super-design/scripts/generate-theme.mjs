#!/usr/bin/env node
/**
 * generate-theme.mjs — emits framework-native theme code from DESIGN.md.
 *
 * Usage:
 *   node generate-theme.mjs DESIGN.md --target=tailwind-v4
 *   node generate-theme.mjs DESIGN.md --target=tailwind-v3
 *   node generate-theme.mjs DESIGN.md --target=shadcn
 *   node generate-theme.mjs DESIGN.md --target=mui
 *   node generate-theme.mjs DESIGN.md --target=radix
 *   node generate-theme.mjs DESIGN.md --target=geist
 *
 * Options:
 *   --out <path>       write to file instead of stdout
 *   --mode extend|replace   (tailwind-v4 only; default: extend)
 *
 * Reads the semantic color table, token blocks, and prints a single file
 * you can drop into the project. Does NOT write without --out so you can
 * preview the diff.
 */

import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const filePath = args[0];
const getFlag = (name, def = null) => {
  const idx = args.findIndex(a => a === `--${name}` || a.startsWith(`--${name}=`));
  if (idx === -1) return def;
  const tok = args[idx];
  if (tok.includes('=')) return tok.split('=', 2)[1];
  return args[idx + 1] || def;
};
const target = getFlag('target') || 'tailwind-v4';
const out = getFlag('out');
const mode = getFlag('mode', 'extend');

if (!filePath || !fs.existsSync(filePath)) {
  console.error('Usage: generate-theme.mjs DESIGN.md --target=<adapter> [--out path] [--mode extend|replace]');
  process.exit(2);
}

const md = fs.readFileSync(filePath, 'utf8');

// --------------------------------------------------------------
// Parse ```tokens <group>\n- name (type): value``` blocks
// --------------------------------------------------------------

function parseTokenBlocks(md) {
  const out = {};
  const re = /```tokens\s+([\w.-]+)\n([\s\S]*?)```/g;
  let m;
  while ((m = re.exec(md)) !== null) {
    const group = m[1];
    const body = m[2];
    const entries = {};
    for (const line of body.split('\n')) {
      const em = line.match(/^-\s+([\w.-]+)\s*\(([\w]+)\):\s*(.+?)(\s+#.*)?$/);
      if (!em) continue;
      entries[em[1]] = { type: em[2], value: em[3].trim(), description: (em[4] || '').replace(/^\s*#\s*/, '') };
    }
    out[group] = entries;
  }
  return out;
}

// --------------------------------------------------------------
// Parse semantic color table (section 2.2)
// --------------------------------------------------------------

function parseSemanticColors(md) {
  const rows = { light: {}, dark: {} };
  const lines = md.split('\n');
  let inTable = false;
  for (const line of lines) {
    if (/\|\s*Token\s*\|\s*Light\s*\|\s*Dark\s*\|/i.test(line)) { inTable = true; continue; }
    if (inTable && /^\|[-\s:|]+\|$/.test(line)) continue;
    if (inTable && !line.trim().startsWith('|')) { inTable = false; continue; }
    if (inTable) {
      const cells = line.split('|').map(c => c.trim());
      if (cells.length < 4) continue;
      const name = cells[1].replace(/`/g, '');
      if (!name.startsWith('--color-')) continue;
      rows.light[name] = cells[2];
      rows.dark[name]  = cells[3];
    }
  }
  return rows;
}

// --------------------------------------------------------------
// Resolve {color.brand.500} aliases
// --------------------------------------------------------------

function resolve(value, blocks) {
  if (!value) return '';
  const m = value.match(/\{([\w.-]+)\}/);
  if (!m) return value;
  const parts = m[1].split('.');
  if (parts.length < 2) return value;
  const group = parts.slice(0, -1).join('.');
  const key = parts[parts.length - 1];
  const entry = blocks[group]?.[key];
  return entry ? entry.value : value;
}

// --------------------------------------------------------------
// Framework adapters
// --------------------------------------------------------------

function emitTailwindV4(blocks, semantic, { mode }) {
  const colors = [];
  if (mode === 'replace') colors.push('  --color-*: initial;');
  colors.push('  --color-white: #fff;');
  colors.push('  --color-black: #000;');
  colors.push('  --color-transparent: transparent;');
  colors.push('  --color-current: currentColor;');

  // Emit primitive neutral + brand + status
  for (const g of ['color.neutral', 'color.brand', 'color.status']) {
    if (!blocks[g]) continue;
    colors.push('');
    colors.push(`  /* ${g} */`);
    for (const [k, v] of Object.entries(blocks[g])) {
      const key = g.includes('status') ? k : `${g.split('.')[1]}-${k}`;
      colors.push(`  --color-${key}: ${v.value};`);
    }
  }

  // Semantic — light mode values in @theme, dark overrides below
  colors.push('');
  colors.push('  /* semantic (light) */');
  for (const [name, val] of Object.entries(semantic.light)) {
    colors.push(`  ${name}: ${resolve(val, blocks)};`);
  }

  // Typography
  const type = [];
  if (blocks['font.family']) {
    for (const [k, v] of Object.entries(blocks['font.family'])) {
      type.push(`  --font-${k}: ${v.value};`);
    }
  }
  if (blocks['font.weight']) {
    for (const [k, v] of Object.entries(blocks['font.weight'])) {
      type.push(`  --font-weight-${k}: ${v.value};`);
    }
  }

  // Spacing base + role aliases
  const sp = [];
  sp.push('  --spacing: 0.25rem;  /* 4px base */');
  if (blocks['inset']) {
    for (const [k, v] of Object.entries(blocks['inset']))  sp.push(`  --inset-${k}: ${resolve(v.value, blocks)};`);
  }
  if (blocks['stack']) {
    for (const [k, v] of Object.entries(blocks['stack']))  sp.push(`  --stack-${k}: ${resolve(v.value, blocks)};`);
  }
  if (blocks['inline']) {
    for (const [k, v] of Object.entries(blocks['inline'])) sp.push(`  --inline-${k}: ${resolve(v.value, blocks)};`);
  }

  // Radii
  const rd = [];
  if (blocks['radius']) {
    for (const [k, v] of Object.entries(blocks['radius'])) rd.push(`  --radius-${k}: ${v.value};`);
  }

  // Shadows
  const sh = [];
  if (blocks['shadow']) {
    for (const [k, v] of Object.entries(blocks['shadow'])) sh.push(`  --shadow-${k}: ${v.value};`);
  }

  // Motion
  const mo = [];
  if (blocks['duration']) {
    for (const [k, v] of Object.entries(blocks['duration'])) mo.push(`  --duration-${k}: ${v.value};`);
  }
  if (blocks['ease']) {
    for (const [k, v] of Object.entries(blocks['ease'])) {
      const vv = v.value.replace(/^\[(.*)\]$/, 'cubic-bezier($1)');
      mo.push(`  --ease-${k}: ${vv};`);
    }
  }

  // Dark mode overrides
  const dark = [];
  for (const [name, val] of Object.entries(semantic.dark)) {
    dark.push(`  ${name}: ${resolve(val, blocks)};`);
  }

  return `/* Generated from DESIGN.md by super-design generate-theme.mjs */
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
${colors.join('\n')}

  /* typography */
${type.join('\n')}

  /* spacing */
${sp.join('\n')}

  /* radii */
${rd.join('\n')}

  /* shadows */
${sh.join('\n')}

  /* motion */
${mo.join('\n')}
}

:root { color-scheme: light; }
.dark {
  color-scheme: dark;
${dark.join('\n')}
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

@media (prefers-contrast: more) {
  :root { --color-border: var(--color-border-strong, var(--color-border)); }
}
`;
}

function emitShadcn(blocks, semantic) {
  // Convert hex/oklch to HSL triplet — naive hex → HSL only.
  function toHslTriplet(colorStr) {
    const hexMatch = colorStr.match(/#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})/);
    if (!hexMatch) return '0 0% 0%';
    let hex = hexMatch[1];
    if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
    const r = parseInt(hex.slice(0, 2), 16) / 255;
    const g = parseInt(hex.slice(2, 4), 16) / 255;
    const b = parseInt(hex.slice(4, 6), 16) / 255;
    const max = Math.max(r, g, b), min = Math.min(r, g, b);
    const l = (max + min) / 2;
    let h = 0, s = 0;
    if (max !== min) {
      const d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      switch (max) {
        case r: h = (g - b) / d + (g < b ? 6 : 0); break;
        case g: h = (b - r) / d + 2; break;
        case b: h = (r - g) / d + 4; break;
      }
      h *= 60;
    }
    return `${Math.round(h)} ${Math.round(s * 100)}% ${Math.round(l * 100)}%`;
  }

  const map = {
    '--color-bg':              'background',
    '--color-fg':              'foreground',
    '--color-surface':         'card',
    '--color-fg-muted':        'muted-foreground',
    '--color-surface-raised':  'muted',
    '--color-accent':          'primary',
    '--color-fg-on-accent':    'primary-foreground',
    '--color-danger':          'destructive',
    '--color-border':          'border',
    '--color-focus-ring':      'ring',
  };

  const emit = (mode) => {
    const vars = semantic[mode];
    const lines = [];
    for (const [sk, shadcn] of Object.entries(map)) {
      const resolved = resolve(vars[sk], blocks);
      if (!resolved) continue;
      lines.push(`    --${shadcn}: ${toHslTriplet(resolved)};`);
    }
    lines.push('    --radius: 0.5rem;');
    return lines.join('\n');
  };

  return `/* Generated from DESIGN.md — drop into app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
${emit('light')}
  }
  .dark {
${emit('dark')}
  }
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; }
  :focus-visible {
    @apply outline-none;
    box-shadow:
      0 0 0 2px hsl(var(--background)),
      0 0 0 5px hsl(var(--ring));
  }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
`;
}

function emitMui(blocks, semantic) {
  const brand = blocks['color.brand']?.['500']?.value || '#6366f1';
  const danger = blocks['color.status']?.['danger-500']?.value || '#ef4444';
  const success = blocks['color.status']?.['success-500']?.value || '#10b981';
  const warning = blocks['color.status']?.['warning-500']?.value || '#f59e0b';
  const radiusMd = blocks['radius']?.['md']?.value || '6px';
  const radiusLg = blocks['radius']?.['lg']?.value || '8px';
  const fontSans = blocks['font.family']?.['sans']?.value || '"Inter Variable", system-ui, sans-serif';

  return `// Generated from DESIGN.md — drop into theme.ts
import { createTheme } from "@mui/material/styles";
import type { ThemeOptions } from "@mui/material/styles";

const base = (mode: "light" | "dark"): ThemeOptions => ({
  palette: {
    mode,
    primary:    { main: "${brand}", contrastText: "#ffffff" },
    error:      { main: "${danger}" },
    success:    { main: "${success}" },
    warning:    { main: "${warning}" },
    background: {
      default: mode === "light" ? "${resolve(semantic.light['--color-bg'], blocks)}" : "${resolve(semantic.dark['--color-bg'], blocks)}",
      paper:   mode === "light" ? "${resolve(semantic.light['--color-surface'], blocks)}" : "${resolve(semantic.dark['--color-surface'], blocks)}",
    },
    text: {
      primary:   mode === "light" ? "${resolve(semantic.light['--color-fg'], blocks)}" : "${resolve(semantic.dark['--color-fg'], blocks)}",
      secondary: mode === "light" ? "${resolve(semantic.light['--color-fg-muted'], blocks)}" : "${resolve(semantic.dark['--color-fg-muted'], blocks)}",
    },
    divider:    mode === "light" ? "${resolve(semantic.light['--color-border'], blocks)}" : "${resolve(semantic.dark['--color-border'], blocks)}",
  },
  shape: { borderRadius: ${parseInt(radiusMd)} },
  spacing: 4,
  typography: {
    fontFamily: ${JSON.stringify(fontSans)},
    fontWeightRegular: 400,
    fontWeightMedium:  500,
    fontWeightBold:    700,
    button: { textTransform: "none", fontWeight: 500 },
  },
  transitions: {
    duration: { shortest: 75, shorter: 150, short: 200, standard: 200, complex: 300 },
    easing: {
      easeOut:   "cubic-bezier(0.2, 0, 0, 1)",
      easeIn:    "cubic-bezier(0.4, 0, 1, 1)",
      easeInOut: "cubic-bezier(0.4, 0, 0.2, 1)",
      sharp:     "cubic-bezier(0.4, 0, 0.6, 1)",
    },
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        "@media (prefers-reduced-motion: reduce)": {
          "*, *::before, *::after": {
            animationDuration: "0.01ms !important",
            transitionDuration: "0.01ms !important",
          },
        },
        ":focus-visible": {
          outline: "none",
          boxShadow: \`0 0 0 2px \${mode === "light" ? "${resolve(semantic.light['--color-bg'], blocks)}" : "${resolve(semantic.dark['--color-bg'], blocks)}"}, 0 0 0 5px ${brand}\`,
        },
      },
    },
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: {
          textTransform: "none",
          borderRadius: ${parseInt(radiusMd)},
          fontWeight: 500,
          minHeight: 44,
          minWidth: 44,
          transition: "all 150ms cubic-bezier(0.2, 0, 0, 1)",
          "&:active": { transform: "scale(0.98)" },
        },
      },
    },
    MuiCard: {
      defaultProps: { elevation: 0 },
      styleOverrides: { root: { borderRadius: ${parseInt(radiusLg)} } },
    },
  },
});

export const lightTheme = createTheme(base("light"));
export const darkTheme  = createTheme(base("dark"));
`;
}

// --------------------------------------------------------------
// Run
// --------------------------------------------------------------

const blocks = parseTokenBlocks(md);
const semantic = parseSemanticColors(md);

if (Object.keys(semantic.light).length === 0) {
  console.error('[design-md] could not parse semantic color table — ensure section 2.2 has a `| Token | Light | Dark |` table');
  process.exit(2);
}

let output;
switch (target) {
  case 'tailwind-v4': output = emitTailwindV4(blocks, semantic, { mode }); break;
  case 'shadcn':      output = emitShadcn(blocks, semantic); break;
  case 'mui':         output = emitMui(blocks, semantic); break;
  case 'tailwind-v3':
  case 'radix':
  case 'geist':
    console.error(`[design-md] target ${target} — see references/framework-adapters/${target}.md for manual template`);
    console.error('[design-md] codegen is implemented for: tailwind-v4, shadcn, mui');
    process.exit(1);
  default:
    console.error(`[design-md] unknown target: ${target}`);
    process.exit(2);
}

if (out) {
  fs.writeFileSync(out, output);
  console.error(`[design-md] wrote ${output.split('\n').length} lines to ${out}`);
} else {
  process.stdout.write(output);
}
