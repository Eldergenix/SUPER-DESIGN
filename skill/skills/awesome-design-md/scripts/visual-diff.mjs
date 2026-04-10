#!/usr/bin/env node
/**
 * visual-diff.mjs — pixel diff wrapper using odiff-bin with pixelmatch fallback.
 *
 * Usage:
 *   node visual-diff.mjs <reference.png> <actual.png> <diff.png> [threshold=0.1]
 *
 * Exit code:
 *   0 if score >= QUALITY_THRESHOLD
 *   1 if score < QUALITY_THRESHOLD
 *
 * Also writes visual-diff.json with the full report.
 */

import fs from 'node:fs';
import path from 'node:path';

const [, , refArg, actualArg, diffArg, thrArg = '0.1'] = process.argv;

if (!refArg || !actualArg || !diffArg) {
  console.error('Usage: node visual-diff.mjs <ref.png> <actual.png> <diff.png> [threshold=0.1]');
  process.exit(2);
}

const ref = path.resolve(refArg);
const actual = path.resolve(actualArg);
const diff = path.resolve(diffArg);
const threshold = Number(thrArg);
const QUALITY_THRESHOLD = Number(process.env.AWESOME_DESIGN_QUALITY_THRESHOLD || 95);

if (!fs.existsSync(ref))    { console.error(`Reference not found: ${ref}`);    process.exit(2); }
if (!fs.existsSync(actual)) { console.error(`Actual not found: ${actual}`);    process.exit(2); }

let diffPct = 100;
let diffPixels = 0;
let engine = 'unknown';
let reason = 'ok';

// -------- Try odiff-bin (fast native) --------
try {
  const { compare } = await import('odiff-bin');
  const result = await compare(ref, actual, diff, {
    threshold,
    antialiasing: true,
    outputDiffMask: false,
    diffColor: '#ff0000',
  });
  engine = 'odiff';
  if (result.match) {
    diffPct = 0;
    diffPixels = 0;
  } else {
    diffPct = result.diffPercentage ?? 100;
    diffPixels = result.diffCount ?? 0;
    reason = result.reason ?? 'pixel-diff';
  }
} catch (odiffErr) {
  // -------- Fallback: pixelmatch --------
  try {
    const { default: pixelmatch } = await import('pixelmatch');
    const { PNG } = await import('pngjs');

    const refImg = PNG.sync.read(fs.readFileSync(ref));
    const actImg = PNG.sync.read(fs.readFileSync(actual));

    if (refImg.width !== actImg.width || refImg.height !== actImg.height) {
      throw new Error(`Dimension mismatch: ref=${refImg.width}x${refImg.height}, actual=${actImg.width}x${actImg.height}`);
    }

    const { width, height } = refImg;
    const diffImg = new PNG({ width, height });

    diffPixels = pixelmatch(
      refImg.data,
      actImg.data,
      diffImg.data,
      width,
      height,
      { threshold, includeAA: true, diffColor: [255, 0, 0], alpha: 0.1 }
    );

    fs.writeFileSync(diff, PNG.sync.write(diffImg));
    diffPct = (diffPixels / (width * height)) * 100;
    engine = 'pixelmatch';
    reason = diffPixels > 0 ? 'pixel-diff' : 'ok';
  } catch (fallbackErr) {
    const report = {
      pass: false,
      score: 0,
      diffPercentage: 100,
      diffPixels: 0,
      reason: 'engine-error',
      error: `odiff: ${odiffErr.message} | pixelmatch: ${fallbackErr.message}`,
      referencePath: ref,
      actualPath: actual,
      diffImagePath: null,
      threshold,
      qualityThreshold: QUALITY_THRESHOLD,
      engine: 'none',
    };
    fs.writeFileSync('visual-diff.json', JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report));
    process.exit(2);
  }
}

// Normalize to 0–100 score
const score = Math.max(0, 100 - diffPct);
const pass = score >= QUALITY_THRESHOLD;

const report = {
  pass,
  score: Number(score.toFixed(2)),
  diffPercentage: Number(diffPct.toFixed(4)),
  diffPixels,
  reason,
  referencePath: ref,
  actualPath: actual,
  diffImagePath: pass ? null : diff,
  threshold,
  qualityThreshold: QUALITY_THRESHOLD,
  engine,
};

fs.writeFileSync('visual-diff.json', JSON.stringify(report, null, 2));
console.log(JSON.stringify(report));
process.exit(pass ? 0 : 1);
