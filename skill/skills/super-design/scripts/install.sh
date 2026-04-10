#!/usr/bin/env bash
# install.sh — installs the super-design skill + hooks + agent shims.
#
# Modes:
#   bash install.sh                → ~/.claude/skills (global)
#   bash install.sh --project      → ./.claude/skills + hooks + shims
#   bash install.sh --both         → global AND project
#   bash install.sh --uninstall    → remove skill + hooks + shims (with confirmation)
#
# Flags:
#   --dry-run         preview changes without writing anything
#   --no-hooks        skip hooks installation
#   --no-agents-md    skip writing AGENTS.md at project root
#   --no-shims        skip cross-agent shim files
#   --no-configs      skip eslint/stylelint/prettier configs
#   --force           overwrite existing files without prompting
#   --project-root P  explicit project root (default: $PWD)
#   --version         print installer version
#
# Idempotent. Records installed version in ./.claude/super-design.install.json
# for migration detection. Rollback on failure via snapshot restore.

set -eo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

SKILL_SRC="$( cd "${SCRIPT_DIR}/.." && pwd )"  # skills/super-design/
SKILL_NAME="super-design"
INSTALLER_VERSION="1.1.0"

MODE="global"
INSTALL_HOOKS=1
INSTALL_AGENTS_MD=1
INSTALL_SHIMS=1
INSTALL_CONFIGS=1
FORCE=0
DRY_RUN=0
UNINSTALL=0
PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"

while [ $# -gt 0 ]; do
  case "$1" in
    --project)         MODE="project" ;;
    --global)          MODE="global" ;;
    --both)            MODE="both" ;;
    --uninstall)       UNINSTALL=1 ;;
    --dry-run)         DRY_RUN=1 ;;
    --no-hooks)        INSTALL_HOOKS=0 ;;
    --no-agents-md)    INSTALL_AGENTS_MD=0 ;;
    --no-shims)        INSTALL_SHIMS=0 ;;
    --no-configs)      INSTALL_CONFIGS=0 ;;
    --force)           FORCE=1 ;;
    --project-root)    shift; PROJECT_ROOT="$1" ;;
    --project-root=*)  PROJECT_ROOT="${1#*=}" ;;
    --version)         echo "super-design installer $INSTALLER_VERSION"; exit 0 ;;
    --help|-h)
      grep -E '^# ' "$0" | sed 's/^# //'
      exit 0 ;;
    *) err "Unknown flag: $1"; exit 2 ;;
  esac
  shift
done

# -------- Destinations --------
HOME_SKILLS="$HOME/.claude/skills/$SKILL_NAME"
PROJECT_SKILLS="$PROJECT_ROOT/.claude/skills/$SKILL_NAME"
PROJECT_SETTINGS="$PROJECT_ROOT/.claude/settings.json"
HOME_SETTINGS="$HOME/.claude/settings.json"
PROJECT_MANIFEST="$PROJECT_ROOT/.claude/super-design.install.json"
SNAPSHOT_DIR=""

# -------- Dry-run / real copy wrapper --------
action() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# -------- Snapshot / rollback --------
take_snapshot() {
  SNAPSHOT_DIR=$(mktemp -d)
  info "Snapshot: $SNAPSHOT_DIR"
  for f in "$PROJECT_ROOT/.claude/settings.json" "$PROJECT_ROOT/AGENTS.md" "$PROJECT_ROOT/CLAUDE.md" "$PROJECT_ROOT/GEMINI.md" "$PROJECT_ROOT/DESIGN.md"; do
    if [ -f "$f" ]; then
      mkdir -p "$SNAPSHOT_DIR$(dirname "$f")"
      cp "$f" "$SNAPSHOT_DIR$f" 2>/dev/null || true
    fi
  done
}

rollback() {
  if [ -z "$SNAPSHOT_DIR" ] || [ ! -d "$SNAPSHOT_DIR" ]; then return; fi
  warn "Rolling back from snapshot $SNAPSHOT_DIR"
  if [ -d "$SNAPSHOT_DIR$PROJECT_ROOT" ]; then
    find "$SNAPSHOT_DIR$PROJECT_ROOT" -type f | while read -r src; do
      dest="${src#$SNAPSHOT_DIR}"
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
    done
  fi
  err "Rollback complete. Install failed."
}

cleanup_snapshot() {
  [ -n "$SNAPSHOT_DIR" ] && [ -d "$SNAPSHOT_DIR" ] && rm -rf "$SNAPSHOT_DIR" || true
}

trap 'rc=$?; [ $rc -ne 0 ] && rollback; cleanup_snapshot' EXIT

# -------- Uninstall --------
if [ "$UNINSTALL" -eq 1 ]; then
  info "Uninstalling super-design..."

  # Remove skill directories
  [ -d "$HOME_SKILLS" ]    && action rm -rf "$HOME_SKILLS"    && info "Removed $HOME_SKILLS"
  [ -d "$PROJECT_SKILLS" ] && action rm -rf "$PROJECT_SKILLS" && info "Removed $PROJECT_SKILLS"

  # Remove hooks from settings.json files (surgical — remove only our entries)
  for settings in "$HOME_SETTINGS" "$PROJECT_SETTINGS"; do
    [ -f "$settings" ] || continue
    if [ "$DRY_RUN" -eq 1 ]; then
      info "[dry-run] would strip super-design hooks from $settings"
      continue
    fi

    tmp=$(mktemp)
    # Prefer jq if available
    if command -v jq >/dev/null 2>&1; then
      jq 'if .hooks then
        .hooks |= with_entries(
          .value |= map(
            .hooks |= map(select(.command | test("super-design") | not))
          )
          | .value |= map(select(.hooks | length > 0))
        )
        | .hooks |= with_entries(select(.value | length > 0))
        | if (.hooks | length) == 0 then del(.hooks) else . end
      else . end' "$settings" > "$tmp" 2>/dev/null || cp "$settings" "$tmp"
    else
      # Fallback: python3
      if command -v python3 >/dev/null 2>&1; then
        python3 - "$settings" > "$tmp" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
  try: d = json.load(f)
  except: d = {}
if "hooks" in d:
  for event, matchers in list(d["hooks"].items()):
    new = []
    for m in matchers:
      m["hooks"] = [h for h in m.get("hooks", []) if "super-design" not in (h.get("command") or "")]
      if m["hooks"]: new.append(m)
    if new: d["hooks"][event] = new
    else: del d["hooks"][event]
  if not d["hooks"]: del d["hooks"]
print(json.dumps(d, indent=2))
PYEOF
      else
        warn "Cannot strip hooks from $settings — install jq or python3. File untouched."
        continue
      fi
    fi
    mv "$tmp" "$settings"
    info "Stripped hooks from $settings"
  done

  # Remove shim files (only if they still point to our skill)
  for shim in "$PROJECT_ROOT/AGENTS.md" "$PROJECT_ROOT/CLAUDE.md" "$PROJECT_ROOT/GEMINI.md" \
              "$PROJECT_ROOT/.cursor/rules/super-design.mdc" \
              "$PROJECT_ROOT/.github/copilot-instructions.md" \
              "$PROJECT_ROOT/.windsurf/rules/design-system.md" \
              "$PROJECT_ROOT/.continue/rules/design-system.md" \
              "$PROJECT_ROOT/.clinerules/design-system.md"; do
    if [ -f "$shim" ] && grep -q 'super-design' "$shim" 2>/dev/null; then
      action rm -f "$shim"
      info "Removed $shim"
    fi
  done

  # Remove install manifest
  [ -f "$PROJECT_MANIFEST" ] && action rm -f "$PROJECT_MANIFEST"

  info "Uninstall complete. DESIGN.md NOT removed (it's your design system)."
  exit 0
fi

# -------- Snapshot before changes --------
[ "$DRY_RUN" -eq 0 ] && take_snapshot

# -------- Copy skill files (excluding .git, .DS_Store) --------
copy_skill() {
  local dest="$1"
  info "Copying skill → $dest"
  action mkdir -p "$dest"

  # Use tar pipe to exclude junk files — works on macOS and Linux
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] would copy skill source (excluding .git, .DS_Store, __pycache__)\n'
    return 0
  fi

  (cd "$SKILL_SRC" && tar \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='node_modules' \
    -cf - .) | (cd "$dest" && tar -xf -)

  # Ensure scripts are executable
  find "$dest/scripts" -type f \( -name '*.sh' -o -name '*.mjs' \) -exec chmod +x {} \; 2>/dev/null || true
}

case "$MODE" in
  global)  copy_skill "$HOME_SKILLS" ;;
  project) copy_skill "$PROJECT_SKILLS" ;;
  both)    copy_skill "$HOME_SKILLS"; copy_skill "$PROJECT_SKILLS" ;;
esac

# -------- Merge hooks into settings.json --------
merge_hooks() {
  local settings_path="$1"
  local template="$SKILL_SRC/templates/settings.json.template"

  [ ! -f "$template" ] && { warn "Hook template missing"; return 0; }

  action mkdir -p "$(dirname "$settings_path")"

  if [ ! -f "$settings_path" ]; then
    info "Creating new $settings_path"
    action cp "$template" "$settings_path"
    return 0
  fi

  info "Merging hooks into $settings_path"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "[dry-run] would merge super-design hooks"
    return 0
  fi

  local tmp
  tmp=$(mktemp)

  if command -v jq >/dev/null 2>&1; then
    # Use jq to do a proper deep-merge with dedup by command
    jq -s '
      def merge_hooks(a; b):
        a as $a | b as $b |
        ($a.hooks // {}) as $ah |
        ($b.hooks // {}) as $bh |
        reduce ($ah | keys_unsorted[]) as $ev ($bh;
          .[$ev] = (
            ($bh[$ev] // []) + ($ah[$ev] // [])
            | group_by(.matcher // "")
            | map({
                matcher: (.[0].matcher // null),
                hooks: (map(.hooks // []) | add | unique_by(.command))
              } | with_entries(select(.value != null)))
          )
        );
      (.[0] // {}) * (.[1] // {}) | .hooks = merge_hooks(.[1]; .[0])
    ' "$settings_path" "$template" > "$tmp" 2>/dev/null || {
      warn "jq merge failed, falling back to python3"
      if command -v python3 >/dev/null 2>&1; then
        python3 - "$settings_path" "$template" > "$tmp" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
  try: base = json.load(f)
  except: base = {}
with open(sys.argv[2]) as f:
  new = json.load(f)
base.setdefault("hooks", {})
for event, matchers in new.get("hooks", {}).items():
  existing = base["hooks"].setdefault(event, [])
  existing_cmds = set()
  for m in existing:
    for h in m.get("hooks", []):
      if h.get("command"): existing_cmds.add(h["command"])
  for m in matchers:
    new_hooks = [h for h in m.get("hooks", []) if h.get("command") not in existing_cmds]
    if new_hooks: existing.append({**m, "hooks": new_hooks})
print(json.dumps(base, indent=2))
PYEOF
      fi
    }
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$settings_path" "$template" > "$tmp" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
  try: base = json.load(f)
  except: base = {}
with open(sys.argv[2]) as f:
  new = json.load(f)
base.setdefault("hooks", {})
for event, matchers in new.get("hooks", {}).items():
  existing = base["hooks"].setdefault(event, [])
  existing_cmds = set()
  for m in existing:
    for h in m.get("hooks", []):
      if h.get("command"): existing_cmds.add(h["command"])
  for m in matchers:
    new_hooks = [h for h in m.get("hooks", []) if h.get("command") not in existing_cmds]
    if new_hooks: existing.append({**m, "hooks": new_hooks})
print(json.dumps(base, indent=2))
PYEOF
  else
    warn "Need jq or python3 to merge hooks. Settings.json left untouched."
    return 1
  fi

  mv "$tmp" "$settings_path"
}

if [ "$INSTALL_HOOKS" -eq 1 ]; then
  case "$MODE" in
    global|both)  merge_hooks "$HOME_SETTINGS" ;;
  esac
  case "$MODE" in
    project|both) merge_hooks "$PROJECT_SETTINGS" ;;
  esac
fi

# -------- Write shim files and AGENTS.md --------
write_if_absent() {
  local src="$1" dest="$2"
  if [ -f "$dest" ] && [ "$FORCE" -eq 0 ]; then
    warn "Exists (use --force): $dest"
    return 0
  fi
  action mkdir -p "$(dirname "$dest")"
  action cp "$src" "$dest"
  info "Wrote $dest"
}

if [ "$MODE" != "global" ]; then
  if [ "$INSTALL_AGENTS_MD" -eq 1 ]; then
    write_if_absent "$SKILL_SRC/templates/AGENTS.md" "$PROJECT_ROOT/AGENTS.md"
  fi

  if [ "$INSTALL_SHIMS" -eq 1 ]; then
    SHIMS_DIR="$SKILL_SRC/templates/shims"
    write_if_absent "$SHIMS_DIR/CLAUDE.md"                "$PROJECT_ROOT/CLAUDE.md"
    write_if_absent "$SHIMS_DIR/GEMINI.md"                "$PROJECT_ROOT/GEMINI.md"
    write_if_absent "$SHIMS_DIR/cursor-rule.mdc"          "$PROJECT_ROOT/.cursor/rules/super-design.mdc"
    write_if_absent "$SHIMS_DIR/copilot-instructions.md"  "$PROJECT_ROOT/.github/copilot-instructions.md"
    write_if_absent "$SHIMS_DIR/windsurf-rule.md"         "$PROJECT_ROOT/.windsurf/rules/design-system.md"
    write_if_absent "$SHIMS_DIR/continue-rule.md"         "$PROJECT_ROOT/.continue/rules/design-system.md"
    write_if_absent "$SHIMS_DIR/cline-rule.md"            "$PROJECT_ROOT/.clinerules/design-system.md"
  fi

  if [ "$INSTALL_CONFIGS" -eq 1 ]; then
    CFG_DIR="$SKILL_SRC/templates/configs"
    [ -d "$CFG_DIR" ] && {
      write_if_absent "$CFG_DIR/.eslintrc.design-md.json"   "$PROJECT_ROOT/.eslintrc.design-md.json"
      write_if_absent "$CFG_DIR/.stylelintrc.design-md.json" "$PROJECT_ROOT/.stylelintrc.design-md.json"
      write_if_absent "$CFG_DIR/playwright.design-md.config.ts" "$PROJECT_ROOT/playwright.design-md.config.ts"
    }
  fi

  # DESIGN.md bootstrap
  if [ ! -f "$PROJECT_ROOT/DESIGN.md" ]; then
    info "No DESIGN.md found — copying enhanced template"
    action cp "$SKILL_SRC/DESIGN.md" "$PROJECT_ROOT/DESIGN.md"
  fi
fi

# -------- Write install manifest (version tracking) --------
if [ "$DRY_RUN" -eq 0 ] && [ "$MODE" != "global" ]; then
  mkdir -p "$(dirname "$PROJECT_MANIFEST")"
  cat > "$PROJECT_MANIFEST" <<EOF
{
  "installer_version": "$INSTALLER_VERSION",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mode": "$MODE",
  "project_root": "$PROJECT_ROOT",
  "hooks_installed": $([ "$INSTALL_HOOKS" -eq 1 ] && echo true || echo false),
  "shims_installed": $([ "$INSTALL_SHIMS" -eq 1 ] && echo true || echo false)
}
EOF
fi

# -------- Disarm rollback trap on success --------
trap - EXIT
cleanup_snapshot

# -------- Summary --------
ok ""
ok "✓ super-design $INSTALLER_VERSION installed"
ok ""
if [ "$DRY_RUN" -eq 1 ]; then
  ok "(dry-run — no files changed)"
  ok ""
fi
ok "Next steps:"
ok "  1. Edit $PROJECT_ROOT/DESIGN.md with your brand tokens"
ok "  2. Run: bash $PROJECT_SKILLS/scripts/lint-design-md.sh DESIGN.md"
ok "  3. Run: node $PROJECT_SKILLS/scripts/contrast-check.mjs DESIGN.md"
ok "  4. Run: node $PROJECT_SKILLS/scripts/generate-theme.mjs DESIGN.md --target=<adapter>"
ok "  5. Build UI — hooks validate every edit automatically"
ok ""
ok "Test suite:        bash $PROJECT_SKILLS/scripts/test.sh"
ok "Audit components:  bash $PROJECT_SKILLS/scripts/audit.sh src/"
ok "Uninstall:         bash $PROJECT_SKILLS/scripts/install.sh --uninstall"
