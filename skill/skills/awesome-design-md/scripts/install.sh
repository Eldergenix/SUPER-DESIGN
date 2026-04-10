#!/usr/bin/env bash
# install.sh — installs the awesome-design-md skill + hooks into a target project
# or a user's ~/.claude/skills/ directory.
#
# Modes:
#   bash install.sh                → install to ~/.claude/skills (global)
#   bash install.sh --project      → install to ./.claude/skills (project-local) + add hooks to ./.claude/settings.json
#   bash install.sh --both         → install globally AND add project-local hooks
#   bash install.sh --uninstall    → remove
#
# Flags:
#   --no-hooks          skip hooks installation
#   --no-agents-md      skip writing AGENTS.md at project root
#   --no-shims          skip cross-agent shim files
#   --force             overwrite existing files without prompting
#
# Safe to re-run (idempotent).

set -eo pipefail

# -------- Locate skill source --------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SKILL_SRC="$( cd "$SCRIPT_DIR/.." && pwd )"  # skills/awesome-design-md/
SKILL_NAME="awesome-design-md"

MODE="global"
INSTALL_HOOKS=1
INSTALL_AGENTS_MD=1
INSTALL_SHIMS=1
FORCE=0
UNINSTALL=0

for arg in "$@"; do
  case "$arg" in
    --project)       MODE="project" ;;
    --global)        MODE="global" ;;
    --both)          MODE="both" ;;
    --uninstall)     UNINSTALL=1 ;;
    --no-hooks)      INSTALL_HOOKS=0 ;;
    --no-agents-md)  INSTALL_AGENTS_MD=0 ;;
    --no-shims)      INSTALL_SHIMS=0 ;;
    --force)         FORCE=1 ;;
    --help|-h)
      grep -E '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done

# -------- Helpers --------
log()  { printf '\033[1;36m[design-md]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[design-md]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[design-md]\033[0m %s\n' "$*" >&2; }

# -------- Destinations --------
HOME_SKILLS="$HOME/.claude/skills/$SKILL_NAME"
PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
PROJECT_SKILLS="$PROJECT_ROOT/.claude/skills/$SKILL_NAME"
PROJECT_SETTINGS="$PROJECT_ROOT/.claude/settings.json"
HOME_SETTINGS="$HOME/.claude/settings.json"

# -------- Uninstall --------
if [ "$UNINSTALL" -eq 1 ]; then
  log "Uninstalling..."
  [ -d "$HOME_SKILLS" ]     && rm -rf "$HOME_SKILLS"     && log "Removed $HOME_SKILLS"
  [ -d "$PROJECT_SKILLS" ]  && rm -rf "$PROJECT_SKILLS"  && log "Removed $PROJECT_SKILLS"
  log "Hooks in settings.json NOT removed automatically — edit manually if needed."
  exit 0
fi

# -------- Copy skill files --------
copy_skill() {
  local dest="$1"
  log "Copying skill to $dest"
  mkdir -p "$dest"
  # Use cp -R to preserve structure
  cp -R "$SKILL_SRC/." "$dest/"
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
  chmod +x "$dest/scripts/"*.mjs 2>/dev/null || true
}

case "$MODE" in
  global)
    copy_skill "$HOME_SKILLS" ;;
  project)
    copy_skill "$PROJECT_SKILLS" ;;
  both)
    copy_skill "$HOME_SKILLS"
    copy_skill "$PROJECT_SKILLS" ;;
esac

# -------- Install hooks into settings.json --------
install_hooks() {
  local settings_path="$1"
  local hooks_template="$SKILL_SRC/../../hooks/settings.json.template"

  [ ! -f "$hooks_template" ] && hooks_template="$SKILL_SRC/templates/settings.json.template"
  [ ! -f "$hooks_template" ] && {
    warn "Hooks template not found — skipping hook install"
    return 0
  }

  mkdir -p "$(dirname "$settings_path")"

  if [ ! -f "$settings_path" ]; then
    log "Creating new $settings_path with awesome-design-md hooks"
    cp "$hooks_template" "$settings_path"
    return 0
  fi

  # Merge: use python3 to deep-merge
  log "Merging hooks into existing $settings_path"
  python3 - "$settings_path" "$hooks_template" <<'PYEOF'
import json, sys, os

settings_path = sys.argv[1]
template_path = sys.argv[2]

with open(settings_path) as f:
  try:
    settings = json.load(f)
  except json.JSONDecodeError:
    settings = {}

with open(template_path) as f:
  template = json.load(f)

settings.setdefault("hooks", {})
template_hooks = template.get("hooks", {})

for event, matchers in template_hooks.items():
  existing = settings["hooks"].setdefault(event, [])
  # Dedup by command string
  existing_cmds = set()
  for m in existing:
    for h in m.get("hooks", []):
      if h.get("command"):
        existing_cmds.add(h["command"])
  for m in matchers:
    new_hooks = [h for h in m.get("hooks", []) if h.get("command") not in existing_cmds]
    if new_hooks:
      existing.append({**m, "hooks": new_hooks})

with open(settings_path, "w") as f:
  json.dump(settings, f, indent=2)
print(f"Merged hooks into {settings_path}")
PYEOF
}

if [ "$INSTALL_HOOKS" -eq 1 ]; then
  case "$MODE" in
    global|both) install_hooks "$HOME_SETTINGS" ;;
  esac
  case "$MODE" in
    project|both) install_hooks "$PROJECT_SETTINGS" ;;
  esac
fi

# -------- Write AGENTS.md (universal bridge) at project root --------
write_agents_md() {
  local dest="$PROJECT_ROOT/AGENTS.md"
  if [ -f "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "AGENTS.md already exists at $dest — skipping (use --force to overwrite)"
    return 0
  fi

  local bridge_src="$SKILL_SRC/templates/AGENTS.md"
  if [ ! -f "$bridge_src" ]; then
    warn "AGENTS.md template not found at $bridge_src"
    return 0
  fi

  cp "$bridge_src" "$dest"
  log "Wrote $dest"
}

if [ "$INSTALL_AGENTS_MD" -eq 1 ] && [ "$MODE" != "global" ]; then
  write_agents_md
fi

# -------- Write cross-agent shim files --------
write_shims() {
  local shims_dir="$SKILL_SRC/templates/shims"
  if [ ! -d "$shims_dir" ]; then
    warn "Shims directory not found — skipping"
    return 0
  fi

  # CLAUDE.md
  if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null && log "Wrote CLAUDE.md"
  fi

  # GEMINI.md
  if [ ! -f "$PROJECT_ROOT/GEMINI.md" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/GEMINI.md" "$PROJECT_ROOT/GEMINI.md" 2>/dev/null && log "Wrote GEMINI.md"
  fi

  # .cursor/rules/awesome-design-md.mdc
  mkdir -p "$PROJECT_ROOT/.cursor/rules"
  if [ ! -f "$PROJECT_ROOT/.cursor/rules/awesome-design-md.mdc" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/cursor-rule.mdc" "$PROJECT_ROOT/.cursor/rules/awesome-design-md.mdc" 2>/dev/null && log "Wrote .cursor/rules/awesome-design-md.mdc"
  fi

  # .github/copilot-instructions.md
  mkdir -p "$PROJECT_ROOT/.github"
  if [ ! -f "$PROJECT_ROOT/.github/copilot-instructions.md" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/copilot-instructions.md" "$PROJECT_ROOT/.github/copilot-instructions.md" 2>/dev/null && log "Wrote .github/copilot-instructions.md"
  fi

  # .windsurf/rules/design-system.md
  mkdir -p "$PROJECT_ROOT/.windsurf/rules"
  if [ ! -f "$PROJECT_ROOT/.windsurf/rules/design-system.md" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/windsurf-rule.md" "$PROJECT_ROOT/.windsurf/rules/design-system.md" 2>/dev/null && log "Wrote .windsurf/rules/design-system.md"
  fi

  # .continue/rules/design-system.md
  mkdir -p "$PROJECT_ROOT/.continue/rules"
  if [ ! -f "$PROJECT_ROOT/.continue/rules/design-system.md" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/continue-rule.md" "$PROJECT_ROOT/.continue/rules/design-system.md" 2>/dev/null && log "Wrote .continue/rules/design-system.md"
  fi

  # .clinerules/design-system.md
  mkdir -p "$PROJECT_ROOT/.clinerules"
  if [ ! -f "$PROJECT_ROOT/.clinerules/design-system.md" ] || [ "$FORCE" -eq 1 ]; then
    cp "$shims_dir/cline-rule.md" "$PROJECT_ROOT/.clinerules/design-system.md" 2>/dev/null && log "Wrote .clinerules/design-system.md"
  fi
}

if [ "$INSTALL_SHIMS" -eq 1 ] && [ "$MODE" != "global" ]; then
  write_shims
fi

# -------- DESIGN.md bootstrap --------
if [ "$MODE" != "global" ] && [ ! -f "$PROJECT_ROOT/DESIGN.md" ]; then
  log "No DESIGN.md found in project — copying enhanced template."
  log "EDIT IT with your brand values before building UI."
  cp "$SKILL_SRC/DESIGN.md" "$PROJECT_ROOT/DESIGN.md"
fi

# -------- Summary --------
log ""
log "✓ awesome-design-md skill installed successfully!"
log ""
log "Next steps:"
log "  1. Edit $PROJECT_ROOT/DESIGN.md with your brand tokens"
log "  2. Pick a reference from https://github.com/VoltAgent/awesome-design-md/tree/main/design-md for inspiration"
log "  3. In Claude Code, invoke with: /awesome-design-md or just ask 'build me a themed component'"
log "  4. Hooks will auto-validate every edit for token usage and quality gates"
log ""
log "To uninstall: bash install.sh --uninstall"
