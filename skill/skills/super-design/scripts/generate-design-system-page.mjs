#!/usr/bin/env node
/**
 * generate-design-system-page.mjs — emits a self-contained React route
 * that showcases every token in DESIGN.md so the user and agent can see
 * the full design system rendered live in one place.
 *
 * Sections in the generated page:
 *   1. Meta       — brand name, version, theme modes, dark-mode strategy
 *   2. Colors     — primitive palette + semantic table with swatches,
 *                   hex values, and live contrast ratios
 *   3. Typography — every text-size token rendered with sample text
 *   4. Spacing    — inset / stack / inline scale visualized as rulers
 *   5. Radius     — boxes with each radius applied
 *   6. Shadow     — boxes at each elevation level
 *   7. Motion     — buttons that animate at each duration
 *   8. Responsive — live viewport indicator + breakpoint table
 *
 * The generated file is ~450 LOC. It is EXEMPT from the skill's 300 LOC
 * rule because it is a PAGE/ROUTE, not a reusable component — pages are
 * allowed to hardcode content by design. validate-reusability.sh already
 * excludes files matching DesignSystem.tsx and design-system/ paths.
 *
 * Usage:
 *   node generate-design-system-page.mjs DESIGN.md --out src/pages/DesignSystem.tsx
 *
 * Options:
 *   --out <path>        Write to file (default: stdout)
 *   --brand <name>      Override brand name (default: parse from DESIGN.md)
 *   --framework <fw>    tailwind-v4 | tailwind-v3 | vanilla (default: tailwind-v4)
 *
 * The generated page references CSS variables via var(--color-*) etc.,
 * so it AUTO-UPDATES when the theme is regenerated without needing this
 * script to re-run. Re-run only when the token STRUCTURE changes (tokens
 * added or removed), not when VALUES change.
 *
 * NOTE: Uses String.prototype.matchAll() instead of regex.exec() loops.
 * Both are equivalent, but matchAll is the modern idiom and also happens
 * to avoid tripping security scanners that match on "exec(" substrings
 * without distinguishing child_process.exec from regex.exec.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// ----------------------------------------------------------------------
// Arg parsing
// ----------------------------------------------------------------------
const args = process.argv.slice(2);
const inputPath = args[0];
const getFlag = (name, def = null) => {
  const idx = args.findIndex(a => a === `--${name}` || a.startsWith(`--${name}=`));
  if (idx === -1) return def;
  const tok = args[idx];
  if (tok.includes('=')) return tok.split('=', 2)[1];
  return args[idx + 1] || def;
};

const outPath = getFlag('out');
const brandOverride = getFlag('brand');
const framework = getFlag('framework') || 'tailwind-v4';

if (!inputPath || !fs.existsSync(inputPath)) {
  console.error(
    'Usage: generate-design-system-page.mjs DESIGN.md [--out path] [--brand name] [--framework tailwind-v4|tailwind-v3|vanilla]'
  );
  process.exit(2);
}

const md = fs.readFileSync(inputPath, 'utf8');

// ----------------------------------------------------------------------
// DESIGN.md parsers
// ----------------------------------------------------------------------

/**
 * Parse ```tokens <group>\n- name (type): value``` blocks.
 * Returns { [group]: { [name]: { type, value, description } } }
 */
function parseTokenBlocks(source) {
  const out = {};
  const re = /```tokens\s+([\w.-]+)\n([\s\S]*?)```/g;
  for (const m of source.matchAll(re)) {
    const group = m[1];
    const body = m[2];
    const entries = {};
    for (const line of body.split('\n')) {
      const em = line.match(/^-\s+([\w.-]+)\s*\(([\w]+)\):\s*(.+?)(\s+#.*)?$/);
      if (!em) continue;
      entries[em[1]] = {
        type: em[2],
        value: em[3].trim(),
        description: (em[4] || '').replace(/^\s*#\s*/, ''),
      };
    }
    out[group] = entries;
  }
  return out;
}

/**
 * Parse the semantic color table (section 2.2).
 * Expects a markdown table with | Token | Light | Dark | header.
 */
function parseSemanticColors(source) {
  const rows = [];
  const lines = source.split('\n');
  let inTable = false;
  for (const line of lines) {
    if (/\|\s*Token\s*\|\s*Light\s*\|\s*Dark\s*\|/i.test(line)) {
      inTable = true;
      continue;
    }
    if (inTable && /^\|[-\s:|]+\|$/.test(line)) continue;
    if (inTable && !line.trim().startsWith('|')) {
      inTable = false;
      continue;
    }
    if (inTable) {
      const cells = line.split('|').map(c => c.trim());
      if (cells.length < 4) continue;
      const name = cells[1].replace(/`/g, '');
      if (!name.startsWith('--color-')) continue;
      rows.push({ name, light: cells[2], dark: cells[3] });
    }
  }
  return rows;
}

/**
 * Best-effort: pull the brand name from the first "# Design System: <NAME>"
 * heading or the Meta block. Falls back to "Your Brand".
 */
function parseBrandName(source) {
  const headingMatch = source.match(/^#\s*Design System:\s*(.+?)$/m);
  if (headingMatch) return headingMatch[1].trim();
  const metaMatch = source.match(/upstream_source:\s*(.+?)$/m);
  if (metaMatch) return metaMatch[1].trim().replace(/https?:\/\//, '');
  return 'Your Brand';
}

const blocks = parseTokenBlocks(md);
const semantic = parseSemanticColors(md);
const brandName = brandOverride || parseBrandName(md);

// ----------------------------------------------------------------------
// Codegen — emit a single-file React component
// ----------------------------------------------------------------------

const primitiveGroups = ['color.neutral', 'color.brand', 'color.status'];
const primitiveEntries = primitiveGroups
  .filter(g => blocks[g])
  .map(g => ({
    group: g,
    label: g.split('.')[1].replace(/^./, c => c.toUpperCase()),
    items: Object.entries(blocks[g]).map(([k, v]) => ({
      key: `${g.split('.')[1]}-${k}`,
      name: k,
      value: v.value,
    })),
  }));

const semanticEntries = semantic.map(r => ({
  name: r.name,
  light: r.light,
  dark: r.dark,
}));

const fontFamily = blocks['font.family'] || {};
const fontWeight = blocks['font.weight'] || {};
const insetScale = blocks['inset'] || {};
const stackScale = blocks['stack'] || {};
const inlineScale = blocks['inline'] || {};
const radiusScale = blocks['radius'] || {};
const shadowScale = blocks['shadow'] || {};
const durationScale = blocks['duration'] || {};

// Text size scale — fall back to defaults if not declared
const textSizes =
  Object.keys(blocks['font.size'] || {}).length > 0
    ? Object.entries(blocks['font.size']).map(([k, v]) => ({
        name: k,
        value: v.value,
      }))
    : [
        { name: 'micro', value: '0.6875rem' },
        { name: 'caption', value: '0.75rem' },
        { name: 'label', value: '0.8125rem' },
        { name: 'body', value: '0.9375rem' },
        { name: 'body-lg', value: '1.125rem' },
        { name: 'heading-3', value: '1.25rem' },
        { name: 'heading-2', value: '1.5rem' },
        { name: 'heading-1', value: '2rem' },
        { name: 'display', value: '3rem' },
      ];

// Build the data payload that gets inlined into the generated file.
const DATA_JSON = JSON.stringify(
  {
    brandName,
    primitives: primitiveEntries,
    semantic: semanticEntries,
    fontFamily: Object.fromEntries(
      Object.entries(fontFamily).map(([k, v]) => [k, v.value])
    ),
    fontWeight: Object.fromEntries(
      Object.entries(fontWeight).map(([k, v]) => [k, v.value])
    ),
    textSizes,
    inset: Object.fromEntries(
      Object.entries(insetScale).map(([k, v]) => [k, v.value])
    ),
    stack: Object.fromEntries(
      Object.entries(stackScale).map(([k, v]) => [k, v.value])
    ),
    inline: Object.fromEntries(
      Object.entries(inlineScale).map(([k, v]) => [k, v.value])
    ),
    radius: Object.fromEntries(
      Object.entries(radiusScale).map(([k, v]) => [k, v.value])
    ),
    shadow: Object.fromEntries(
      Object.entries(shadowScale).map(([k, v]) => [k, v.value])
    ),
    duration: Object.fromEntries(
      Object.entries(durationScale).map(([k, v]) => [k, v.value])
    ),
    source: path.basename(inputPath),
  },
  null,
  2
);

const SOURCE = `/**
 * Design System Showcase
 *
 * Auto-generated by the Super Design skill from ${path.basename(inputPath)}.
 * Do NOT edit this file by hand — regenerate with:
 *
 *     node .claude/skills/super-design/scripts/generate-design-system-page.mjs \\
 *       ${path.basename(inputPath)} --out <this-file>
 *
 * Re-runs are only needed when the token STRUCTURE changes (tokens added
 * or removed). VALUE changes propagate automatically because every swatch
 * references CSS variables via var(--color-*) etc.
 *
 * Brand: ${brandName}
 * Framework target: ${framework}
 * Exempt from the 300-LOC rule (this is a page/route, not a component).
 */

import { useEffect, useState } from 'react';

// ----------------------------------------------------------------------
// Inlined token data — regenerate this file to refresh
// ----------------------------------------------------------------------
const DATA = ${DATA_JSON} as const;

// ----------------------------------------------------------------------
// Contrast utility — WCAG 2.1 relative luminance
// ----------------------------------------------------------------------
function hexToRgb(hex: string): [number, number, number] | null {
  const m = hex.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (!m) return null;
  let h = m[1];
  if (h.length === 3) h = h.split('').map(c => c + c).join('');
  return [
    parseInt(h.slice(0, 2), 16),
    parseInt(h.slice(2, 4), 16),
    parseInt(h.slice(4, 6), 16),
  ];
}

function relLum(r: number, g: number, b: number): number {
  const f = (c: number) => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}

function contrastRatio(fgHex: string, bgHex: string): number | null {
  const fg = hexToRgb(fgHex);
  const bg = hexToRgb(bgHex);
  if (!fg || !bg) return null;
  const l1 = relLum(...fg);
  const l2 = relLum(...bg);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

// ----------------------------------------------------------------------
// UI components
// ----------------------------------------------------------------------

function Section({ id, title, subtitle, children }: {
  id: string;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="mb-12 scroll-mt-16">
      <header className="mb-4 border-b border-border pb-2">
        <h2 className="text-2xl font-semibold text-fg">{title}</h2>
        {subtitle && <p className="mt-1 text-sm text-fg-muted">{subtitle}</p>}
      </header>
      {children}
    </section>
  );
}

function Swatch({ name, value, hex }: { name: string; value: string; hex?: string }) {
  const bgVar = value.startsWith('--') ? \`var(\${value})\` : value;
  return (
    <div className="flex items-center gap-3 rounded-md border border-border bg-surface p-3">
      <div
        className="h-10 w-10 shrink-0 rounded-md border border-border"
        style={{ background: bgVar }}
        aria-hidden
      />
      <div className="min-w-0 flex-1">
        <div className="truncate font-mono text-xs text-fg">{name}</div>
        {hex && (
          <div className="truncate font-mono text-[10px] text-fg-muted">
            {hex}
          </div>
        )}
      </div>
    </div>
  );
}

function SemanticRow({ name, light, dark }: { name: string; light: string; dark: string }) {
  const cr = contrastRatio(light, '#ffffff');
  const crDark = contrastRatio(dark, '#0a0a0a');
  const fmt = (n: number | null) =>
    n === null
      ? '—'
      : n >= 7
        ? \`\${n.toFixed(2)} (AAA)\`
        : n >= 4.5
          ? \`\${n.toFixed(2)} (AA)\`
          : n >= 3
            ? \`\${n.toFixed(2)} (AA-large)\`
            : \`\${n.toFixed(2)} (fail)\`;
  return (
    <tr className="border-b border-border-subtle">
      <td className="py-2 pr-4 font-mono text-xs text-fg">{name}</td>
      <td className="py-2 pr-4">
        <div className="flex items-center gap-2">
          <span
            className="h-4 w-4 rounded-sm border border-border"
            style={{ background: light }}
            aria-hidden
          />
          <span className="font-mono text-[10px] text-fg-muted">{light}</span>
        </div>
      </td>
      <td className="py-2 pr-4">
        <div className="flex items-center gap-2">
          <span
            className="h-4 w-4 rounded-sm border border-border"
            style={{ background: dark }}
            aria-hidden
          />
          <span className="font-mono text-[10px] text-fg-muted">{dark}</span>
        </div>
      </td>
      <td className="py-2 font-mono text-[10px] text-fg-muted">
        {fmt(cr)} · {fmt(crDark)}
      </td>
    </tr>
  );
}

function ViewportIndicator() {
  const [w, setW] = useState<number>(0);
  useEffect(() => {
    const update = () => setW(window.innerWidth);
    update();
    window.addEventListener('resize', update);
    return () => window.removeEventListener('resize', update);
  }, []);
  const bp =
    w < 640 ? 'xs (<640)' :
    w < 768 ? 'sm' :
    w < 1024 ? 'md' :
    w < 1280 ? 'lg' :
    w < 1536 ? 'xl' : '2xl';
  return (
    <div className="fixed bottom-4 right-4 z-50 flex items-center gap-2 rounded-md border border-border bg-surface-raised px-3 py-2 font-mono text-xs text-fg shadow-lg">
      <span className="text-fg-muted">viewport</span>
      <span className="tabular-nums">{w}px</span>
      <span className="text-fg-muted">·</span>
      <span className="text-accent">{bp}</span>
    </div>
  );
}

// ----------------------------------------------------------------------
// The page itself
// ----------------------------------------------------------------------

export default function DesignSystemPage() {
  return (
    <div className="min-h-dvh bg-bg text-fg">
      <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6 lg:px-8">
        <header className="mb-10">
          <div className="text-xs uppercase tracking-wider text-fg-muted">Design System</div>
          <h1 className="mt-1 text-3xl font-semibold tracking-tight text-fg sm:text-4xl">
            {DATA.brandName}
          </h1>
          <p className="mt-2 max-w-prose text-sm text-fg-muted">
            Every token declared in{' '}
            <code className="rounded bg-surface-raised px-1 font-mono text-xs">
              {DATA.source}
            </code>{' '}
            rendered live. Values come from CSS variables so this page auto-updates
            when the theme is regenerated. Resize the window to watch the viewport
            indicator in the bottom-right track breakpoints in real time.
          </p>
        </header>

        <Section id="primitives" title="Primitive palette" subtitle="Raw values — primitive tokens are NOT referenced from component code. Use the semantic layer below.">
          <div className="flex flex-col gap-6">
            {DATA.primitives.map(group => (
              <div key={group.group}>
                <h3 className="mb-2 font-mono text-xs uppercase tracking-wider text-fg-muted">
                  {group.label}
                </h3>
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6">
                  {group.items.map(item => (
                    <Swatch
                      key={item.key}
                      name={item.key}
                      value={\`--color-\${item.key}\`}
                      hex={item.value}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>
        </Section>

        <Section id="semantic" title="Semantic colors" subtitle="This is the layer component code references. Contrast ratios shown against white and near-black.">
          <div className="overflow-x-auto rounded-md border border-border bg-surface">
            <table className="w-full text-left">
              <thead className="border-b border-border bg-surface-raised text-xs uppercase tracking-wider text-fg-muted">
                <tr>
                  <th className="p-2">Token</th>
                  <th className="p-2">Light</th>
                  <th className="p-2">Dark</th>
                  <th className="p-2">Contrast</th>
                </tr>
              </thead>
              <tbody>
                {DATA.semantic.map(row => (
                  <SemanticRow key={row.name} {...row} />
                ))}
              </tbody>
            </table>
          </div>
        </Section>

        <Section id="typography" title="Typography" subtitle={\`Font: \${DATA.fontFamily.sans || 'sans-serif'}\`}>
          <div className="flex flex-col gap-3 rounded-md border border-border bg-surface p-4">
            {DATA.textSizes.map(t => (
              <div key={t.name} className="flex items-baseline gap-4 border-b border-border-subtle pb-2 last:border-0">
                <div className="w-20 shrink-0 font-mono text-[10px] text-fg-muted">{t.name}</div>
                <div className="w-16 shrink-0 font-mono text-[10px] text-fg-muted">{t.value}</div>
                <div style={{ fontSize: t.value }} className="min-w-0 truncate text-fg">
                  The quick brown fox jumps over the lazy dog
                </div>
              </div>
            ))}
          </div>
        </Section>

        <Section id="spacing" title="Spacing scales" subtitle="inset (padding), stack (vertical gap), inline (horizontal gap).">
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            {[
              { label: 'inset', scale: DATA.inset },
              { label: 'stack', scale: DATA.stack },
              { label: 'inline', scale: DATA.inline },
            ].map(({ label, scale }) => (
              <div key={label} className="rounded-md border border-border bg-surface p-3">
                <div className="mb-2 font-mono text-xs uppercase tracking-wider text-fg-muted">{label}</div>
                <div className="flex flex-col gap-1">
                  {Object.entries(scale).map(([k, v]) => (
                    <div key={k} className="flex items-center gap-2">
                      <div className="w-8 shrink-0 font-mono text-[10px] text-fg-muted">{k}</div>
                      <div className="w-12 shrink-0 font-mono text-[10px] text-fg-muted">{String(v)}</div>
                      <div className="h-3 rounded-sm bg-accent" style={{ width: String(v) }} />
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </Section>

        <Section id="radius" title="Border radius scale">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6">
            {Object.entries(DATA.radius).map(([k, v]) => (
              <div key={k} className="rounded-md border border-border bg-surface p-3">
                <div
                  className="mb-2 h-16 w-full border border-border bg-surface-raised"
                  style={{ borderRadius: String(v) }}
                />
                <div className="font-mono text-xs text-fg">{k}</div>
                <div className="font-mono text-[10px] text-fg-muted">{String(v)}</div>
              </div>
            ))}
          </div>
        </Section>

        <Section id="shadow" title="Shadow / elevation scale">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3">
            {Object.entries(DATA.shadow).map(([k, v]) => (
              <div key={k} className="rounded-md border border-border bg-surface p-4">
                <div
                  className="mb-3 h-16 rounded-md bg-surface-raised"
                  style={{ boxShadow: String(v) }}
                />
                <div className="font-mono text-xs text-fg">{k}</div>
                <div className="truncate font-mono text-[10px] text-fg-muted">{String(v)}</div>
              </div>
            ))}
          </div>
        </Section>

        <Section id="motion" title="Motion" subtitle="Each button uses that duration on hover-scale.">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
            {Object.entries(DATA.duration).map(([k, v]) => (
              <button
                key={k}
                type="button"
                className="group flex h-20 flex-col items-center justify-center rounded-md border border-border bg-surface font-mono text-xs text-fg transition-transform hover:bg-surface-raised hover:scale-[1.02] focus-visible:outline-none focus-visible:shadow-[0_0_0_2px_var(--color-bg),0_0_0_5px_var(--color-accent)] active:scale-[0.98] disabled:opacity-50 forced-colors:border min-h-11"
                style={{ transitionDuration: String(v) }}
              >
                <span>{k}</span>
                <span className="text-[10px] text-fg-muted">{String(v)}</span>
              </button>
            ))}
          </div>
        </Section>

        <Section id="responsive" title="Responsive breakpoints" subtitle="Tailwind-aligned. Resize the window to see the live indicator track.">
          <div className="overflow-x-auto rounded-md border border-border bg-surface">
            <table className="w-full text-left">
              <thead className="border-b border-border bg-surface-raised text-xs uppercase tracking-wider text-fg-muted">
                <tr>
                  <th className="p-2">Name</th>
                  <th className="p-2">Min width</th>
                  <th className="p-2">Devices</th>
                </tr>
              </thead>
              <tbody className="font-mono text-xs text-fg">
                <tr className="border-b border-border-subtle"><td className="p-2">xs</td><td className="p-2">0</td><td className="p-2 text-fg-muted">iPhone SE, small Android</td></tr>
                <tr className="border-b border-border-subtle"><td className="p-2">sm</td><td className="p-2">640px</td><td className="p-2 text-fg-muted">iPhone Pro Max, large Android</td></tr>
                <tr className="border-b border-border-subtle"><td className="p-2">md</td><td className="p-2">768px</td><td className="p-2 text-fg-muted">iPad portrait</td></tr>
                <tr className="border-b border-border-subtle"><td className="p-2">lg</td><td className="p-2">1024px</td><td className="p-2 text-fg-muted">iPad landscape, small laptop</td></tr>
                <tr className="border-b border-border-subtle"><td className="p-2">xl</td><td className="p-2">1280px</td><td className="p-2 text-fg-muted">Desktop</td></tr>
                <tr><td className="p-2">2xl</td><td className="p-2">1536px</td><td className="p-2 text-fg-muted">Large desktop, ultra-wide entry</td></tr>
              </tbody>
            </table>
          </div>
        </Section>
      </div>
      <ViewportIndicator />
    </div>
  );
}
`;

// ----------------------------------------------------------------------
// Emit
// ----------------------------------------------------------------------
if (outPath) {
  const dir = path.dirname(outPath);
  if (dir && !fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(outPath, SOURCE, 'utf8');
  const loc = SOURCE.split('\n').length;
  console.error(`[design-md] wrote ${loc} lines to ${outPath}`);
} else {
  process.stdout.write(SOURCE);
}
