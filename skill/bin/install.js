#!/usr/bin/env node
/**
 * Node.js installer for awesome-design-md skill.
 * Wrapper around scripts/install.sh that works on all platforms including Windows (via Git Bash / WSL).
 *
 * Usage:
 *   npx awesome-design-md                  → global install to ~/.claude/skills
 *   npx awesome-design-md --project        → project install to .claude/skills + hooks
 *   npx awesome-design-md --both           → both
 *   npx awesome-design-md --uninstall      → uninstall
 */

import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.resolve(__dirname, '..');
const installSh = path.join(packageRoot, 'skills/awesome-design-md/scripts/install.sh');

if (!fs.existsSync(installSh)) {
  console.error(`[awesome-design-md] install.sh not found at ${installSh}`);
  process.exit(1);
}

const args = process.argv.slice(2);

// Make sure the script is executable
try { fs.chmodSync(installSh, 0o755); } catch {}

const shell = process.platform === 'win32' ? 'bash.exe' : 'bash';
const result = spawnSync(shell, [installSh, ...args], {
  stdio: 'inherit',
  env: { ...process.env, PROJECT_ROOT: process.cwd() },
});

if (result.error) {
  console.error(`[awesome-design-md] Failed to run installer: ${result.error.message}`);
  console.error('[awesome-design-md] Make sure bash is available on your PATH.');
  console.error('[awesome-design-md] On Windows, install Git Bash or WSL.');
  process.exit(1);
}

process.exit(result.status ?? 0);
