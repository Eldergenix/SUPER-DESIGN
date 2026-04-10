#!/usr/bin/env node
/**
 * Node.js installer wrapper for super-design.
 *
 * Cross-platform:
 *   - macOS / Linux → runs scripts/install.sh via /bin/bash
 *   - Windows      → runs scripts/install.sh via Git Bash (C:\Program Files\Git\bin\bash.exe)
 *                     or falls back to pure-Node copy if bash is unavailable.
 *
 * Usage (npm):
 *   npx super-design                  → ~/.claude/skills (global)
 *   npx super-design --project        → .claude/skills + hooks + shims
 *   npx super-design --both
 *   npx super-design --uninstall
 *   npx super-design --dry-run --project
 */

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.resolve(__dirname, '..');
const skillSrc = path.join(packageRoot, 'skills', 'super-design');
const installSh = path.join(skillSrc, 'scripts', 'install.sh');

const args = process.argv.slice(2);

function log(msg) { process.stdout.write(`[design-md] ${msg}\n`); }
function err(msg) { process.stderr.write(`[design-md] ${msg}\n`); }

// ------------------------------------------------------------------
// 1. Try bash (preferred — runs the actual installer with rollback etc.)
// ------------------------------------------------------------------

function findBash() {
  // POSIX first
  for (const candidate of ['/bin/bash', '/usr/bin/bash', '/usr/local/bin/bash']) {
    if (fs.existsSync(candidate)) return candidate;
  }
  // Windows Git Bash
  if (process.platform === 'win32') {
    for (const candidate of [
      'C:\\Program Files\\Git\\bin\\bash.exe',
      'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
      `${os.homedir()}\\AppData\\Local\\Programs\\Git\\bin\\bash.exe`,
    ]) {
      if (fs.existsSync(candidate)) return candidate;
    }
  }
  // PATH lookup
  const whichCmd = process.platform === 'win32' ? 'where' : 'which';
  const result = spawnSync(whichCmd, ['bash'], { encoding: 'utf8' });
  if (result.status === 0) {
    return result.stdout.trim().split(/\r?\n/)[0];
  }
  return null;
}

function runBashInstaller() {
  const bash = findBash();
  if (!bash) return false;

  try {
    fs.chmodSync(installSh, 0o755);
  } catch {}

  // Normalize path for Git Bash on Windows (C:\ → /c/)
  let shPath = installSh;
  if (process.platform === 'win32') {
    shPath = installSh.replace(/^([A-Z]):/, (_, d) => `/${d.toLowerCase()}`).replace(/\\/g, '/');
  }

  const result = spawnSync(bash, [shPath, ...args], {
    stdio: 'inherit',
    env: { ...process.env, PROJECT_ROOT: process.cwd() },
  });

  if (result.error) {
    err(`bash installer failed: ${result.error.message}`);
    return false;
  }
  process.exit(result.status ?? 0);
}

// ------------------------------------------------------------------
// 2. Pure-Node fallback — copies files only, no hook merge or rollback.
//    Runs when bash is unavailable (plain Windows).
// ------------------------------------------------------------------

function runPureNodeFallback() {
  log('bash not found — running pure-Node fallback (limited: no hook merge, no rollback)');

  const mode = args.includes('--project') ? 'project'
             : args.includes('--both')    ? 'both'
             : 'global';
  const dryRun = args.includes('--dry-run');
  const force  = args.includes('--force');
  const projectRoot = process.cwd();

  const homeSkills    = path.join(os.homedir(), '.claude', 'skills', 'super-design');
  const projectSkills = path.join(projectRoot,  '.claude', 'skills', 'super-design');

  const EXCLUDES = new Set(['.git', '.DS_Store', '__pycache__', 'node_modules']);

  function copyDir(src, dest) {
    if (dryRun) { log(`[dry-run] copy ${src} → ${dest}`); return; }
    fs.mkdirSync(dest, { recursive: true });
    for (const name of fs.readdirSync(src)) {
      if (EXCLUDES.has(name)) continue;
      const srcPath = path.join(src, name);
      const destPath = path.join(dest, name);
      const stat = fs.statSync(srcPath);
      if (stat.isDirectory()) {
        copyDir(srcPath, destPath);
      } else {
        fs.copyFileSync(srcPath, destPath);
        // Preserve exec bit on .sh/.mjs
        if (/\.(sh|mjs)$/.test(name)) {
          try { fs.chmodSync(destPath, 0o755); } catch {}
        }
      }
    }
  }

  function copyIfAbsent(src, dest) {
    if (fs.existsSync(dest) && !force) {
      log(`exists (use --force): ${dest}`);
      return;
    }
    if (dryRun) { log(`[dry-run] write ${dest}`); return; }
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
    log(`wrote ${dest}`);
  }

  if (mode === 'global' || mode === 'both') {
    copyDir(skillSrc, homeSkills);
    log(`Copied skill → ${homeSkills}`);
  }

  if (mode === 'project' || mode === 'both') {
    copyDir(skillSrc, projectSkills);
    log(`Copied skill → ${projectSkills}`);

    // Shim files
    const shims = path.join(skillSrc, 'templates', 'shims');
    copyIfAbsent(path.join(skillSrc, 'templates', 'AGENTS.md'),       path.join(projectRoot, 'AGENTS.md'));
    copyIfAbsent(path.join(shims, 'CLAUDE.md'),                       path.join(projectRoot, 'CLAUDE.md'));
    copyIfAbsent(path.join(shims, 'GEMINI.md'),                       path.join(projectRoot, 'GEMINI.md'));
    copyIfAbsent(path.join(shims, 'cursor-rule.mdc'),                 path.join(projectRoot, '.cursor', 'rules', 'super-design.mdc'));
    copyIfAbsent(path.join(shims, 'copilot-instructions.md'),         path.join(projectRoot, '.github', 'copilot-instructions.md'));
    copyIfAbsent(path.join(shims, 'windsurf-rule.md'),                path.join(projectRoot, '.windsurf', 'rules', 'design-system.md'));
    copyIfAbsent(path.join(shims, 'continue-rule.md'),                path.join(projectRoot, '.continue', 'rules', 'design-system.md'));
    copyIfAbsent(path.join(shims, 'cline-rule.md'),                   path.join(projectRoot, '.clinerules', 'design-system.md'));

    // DESIGN.md bootstrap
    if (!fs.existsSync(path.join(projectRoot, 'DESIGN.md'))) {
      copyIfAbsent(path.join(skillSrc, 'DESIGN.md'), path.join(projectRoot, 'DESIGN.md'));
    }

    // Hook merge via pure Node
    const settingsPath = path.join(projectRoot, '.claude', 'settings.json');
    const templatePath = path.join(skillSrc, 'templates', 'settings.json.template');

    if (fs.existsSync(templatePath)) {
      if (!dryRun) {
        fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
        let base = {};
        if (fs.existsSync(settingsPath)) {
          try { base = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); }
          catch { base = {}; }
        }
        const tmpl = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
        base.hooks = base.hooks || {};
        for (const [event, matchers] of Object.entries(tmpl.hooks || {})) {
          const existing = base.hooks[event] = base.hooks[event] || [];
          const existingCmds = new Set();
          for (const m of existing) for (const h of (m.hooks || [])) if (h.command) existingCmds.add(h.command);
          for (const m of matchers) {
            const newHooks = (m.hooks || []).filter(h => !existingCmds.has(h.command));
            if (newHooks.length) existing.push({ ...m, hooks: newHooks });
          }
        }
        fs.writeFileSync(settingsPath, JSON.stringify(base, null, 2));
        log(`merged hooks into ${settingsPath}`);
      } else {
        log(`[dry-run] would merge hooks into ${settingsPath}`);
      }
    }
  }

  log('✓ pure-Node install complete');
  log('Note: rollback/snapshot not available in fallback mode — use bash installer for production.');
}

// ------------------------------------------------------------------
// Entry
// ------------------------------------------------------------------

if (!fs.existsSync(installSh)) {
  err(`install.sh not found at ${installSh}`);
  process.exit(1);
}

if (runBashInstaller() === false) {
  runPureNodeFallback();
}
