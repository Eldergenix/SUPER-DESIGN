#!/usr/bin/env node
/**
 * screenshot-component.mjs — render a URL/file to PNG via Playwright.
 *
 * Usage:
 *   node screenshot-component.mjs <url-or-file> <out.png> [--viewport=1280x800] [--selector=.my-component] [--dark]
 *
 * Dependencies: playwright (as optional dep of super-design)
 * Install on demand: npm i -D @playwright/test && npx playwright install chromium
 */

import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const urlOrFile = args[0];
const outPath = args[1];

const getFlag = (name, def = null) => {
  const idx = args.findIndex(a => a === `--${name}` || a.startsWith(`--${name}=`));
  if (idx === -1) return def;
  const tok = args[idx];
  if (tok.includes('=')) return tok.split('=', 2)[1];
  return args[idx + 1] || def;
};

if (!urlOrFile || !outPath) {
  console.error('Usage: screenshot-component.mjs <url-or-file> <out.png> [--viewport=WxH] [--selector=.css] [--dark]');
  process.exit(2);
}

const viewportStr = getFlag('viewport', '1280x800');
const [vw, vh] = viewportStr.split('x').map(Number);
const selector = getFlag('selector');
const dark = args.includes('--dark');

let playwright;
try {
  playwright = await import('playwright');
} catch {
  try {
    playwright = await import('@playwright/test');
  } catch {
    console.error('[design-md] playwright is not installed in this project.');
    console.error('[design-md] Install with: npm i -D playwright && npx playwright install chromium');
    process.exit(1);
  }
}

const { chromium } = playwright;

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: vw, height: vh },
  deviceScaleFactor: 2,
  colorScheme: dark ? 'dark' : 'light',
  reducedMotion: 'reduce',
});
const page = await context.newPage();

const target = /^(https?:|file:)/.test(urlOrFile)
  ? urlOrFile
  : `file://${path.resolve(urlOrFile)}`;

try {
  await page.goto(target, { waitUntil: 'networkidle', timeout: 30000 });
} catch (err) {
  console.error(`[design-md] failed to load ${target}: ${err.message}`);
  process.exit(1);
}

// Wait for fonts to finish loading — prevents text shift in the diff
await page.evaluate(() => document.fonts.ready);

// Let any lazy animation settle
await page.waitForTimeout(100);

const outDir = path.dirname(outPath);
fs.mkdirSync(outDir, { recursive: true });

if (selector) {
  const el = await page.$(selector);
  if (!el) {
    console.error(`[design-md] selector not found: ${selector}`);
    await browser.close();
    process.exit(1);
  }
  await el.screenshot({ path: outPath, omitBackground: false });
} else {
  await page.screenshot({ path: outPath, fullPage: true, omitBackground: false });
}

await browser.close();
console.log(JSON.stringify({ path: outPath, viewport: { width: vw, height: vh }, dark, selector }));
