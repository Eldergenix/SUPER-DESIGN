#!/usr/bin/env bash
# _lib.sh — shared helpers sourced by other scripts.
#
# - Pure POSIX-ish. No python3 or jq hard dependency.
# - Handles paths with spaces.
# - Strips JS/CSS comments before content scans to avoid false positives.
# - Provides reliable count helpers that return total matches, not line counts.

# ------------------------------------------------------------------
# JSON from stdin — extract a field with jq if available, else python3,
# else a minimal shell parser for the narrow schemas we care about.
# ------------------------------------------------------------------
read_json_field() {
  # Usage: read_json_field <json> <dot.path>
  local json="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r "${field} // \"\"" 2>/dev/null
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$json" | python3 -c "
import sys, json
try:
  d = json.load(sys.stdin)
  path = '$field'.lstrip('.').split('.')
  for p in path:
    if isinstance(d, dict): d = d.get(p, '')
    else: d = ''
  print(d if isinstance(d, str) else '')
except Exception:
  print('')
" 2>/dev/null
    return
  fi
  # Fallback: naive grep for flat "field":"value" — only works at top level.
  local key="${field##*.}"
  printf '%s' "$json" \
    | tr -d '\n' \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\\1/" \
    || true
}

# ------------------------------------------------------------------
# Strip line and block comments from a source file.
# Handles //, /* */, and leading * in JSDoc.
# Prints cleaned content to stdout.
# ------------------------------------------------------------------
strip_comments() {
  local file="$1"
  [ -f "$file" ] || return 0
  # Use awk: remove /* ... */ (multi-line), then // ... , then trim.
  awk '
    BEGIN { in_block = 0 }
    {
      line = $0
      # Handle block comments that span lines
      while (1) {
        if (in_block) {
          end = index(line, "*/")
          if (end == 0) { line = ""; break }
          line = substr(line, end + 2)
          in_block = 0
        }
        start = index(line, "/*")
        if (start == 0) break
        endp = index(substr(line, start + 2), "*/")
        if (endp == 0) {
          line = substr(line, 1, start - 1)
          in_block = 1
          break
        }
        line = substr(line, 1, start - 1) substr(line, start + endp + 3)
      }
      # Remove line comments (but preserve // inside strings — naive but good enough)
      # Only strip // that are NOT preceded by a : or inside a string literal.
      gsub(/^[[:space:]]*\/\/.*/, "", line)
      gsub(/[[:space:]]+\/\/[^"]*$/, "", line)
      print line
    }
  ' "$file"
}

# ------------------------------------------------------------------
# Count total matches (not matching lines) of an ERE pattern in a file.
# Reliable: returns 0 on no match, n on n matches. Always a clean integer.
# ------------------------------------------------------------------
count_matches() {
  local pattern="$1" file="$2"
  local c
  c=$(grep -oE "$pattern" "$file" 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${c:-0}"
}

# ------------------------------------------------------------------
# Count total matches in content read from stdin.
# ------------------------------------------------------------------
count_matches_stdin() {
  local pattern="$1"
  local c
  c=$(grep -oE "$pattern" 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "${c:-0}"
}

# ------------------------------------------------------------------
# JSX depth heuristic — returns the deepest JSX nesting level by
# counting open tags minus close tags per line, tracking running depth.
# More accurate than "leading whitespace / 2".
# ------------------------------------------------------------------
jsx_max_depth() {
  local file="$1"
  awk '
    BEGIN { depth = 0; max_depth = 0 }
    {
      line = $0
      # Self-closing tags do not change depth
      n_open = gsub(/<[A-Za-z][A-Za-z0-9.]*[^/>]*[^/]>/, "&", line)
      n_close = gsub(/<\/[A-Za-z][A-Za-z0-9.]*>/, "&", line)
      depth += n_open - n_close
      if (depth > max_depth) max_depth = depth
    }
    END { print max_depth + 0 }
  ' "$file"
}

# ------------------------------------------------------------------
# Allowed pixel scale. Values INSIDE this set are OK; anything else
# triggers warn/block depending on the caller.
# ------------------------------------------------------------------
ALLOWED_PX_SCALE='^(0|1|2|3|4|5|6|7|8|9|10|11|12|14|16|18|20|24|28|32|36|40|44|48|56|64|72|80|96|112|128|144|160|192|224|256|288|320)px$'
VIEWPORT_PX_SCALE='^(320|375|640|768|1024|1280|1440|1536|1920)px$'

# ------------------------------------------------------------------
# File exclusion check — returns 0 if file should be SKIPPED by the
# audit (token files, configs, node_modules, build output, etc.).
# ------------------------------------------------------------------
should_skip_file() {
  local file="$1"
  case "$file" in
    */node_modules/*|*/dist/*|*/build/*|*/.next/*|*/out/*|*/.turbo/*|*/coverage/*)
      return 0 ;;
    *tailwind.config.*|*theme.ts|*theme.js|*theme.css|*globals.css|*tokens.json|*tokens.ts|*design-tokens.*)
      return 0 ;;
    *DESIGN.md|*STATE_MATRIX.yaml|*tokens.schema.json)
      return 0 ;;
    */.claude-plugin/*|*/.claude/skills/super-design/*)
      return 0 ;;
  esac
  return 1
}

# ------------------------------------------------------------------
# Determine if a file is a component/style file we should audit.
# ------------------------------------------------------------------
is_auditable_file() {
  local file="$1"
  case "$file" in
    *.tsx|*.jsx|*.ts|*.js|*.mjs|*.cjs|*.vue|*.svelte|*.astro|*.css|*.scss|*.sass)
      return 0 ;;
  esac
  return 1
}

# ------------------------------------------------------------------
# Color / message helpers
# ------------------------------------------------------------------
_color() {
  if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
    printf '\033[%sm%s\033[0m' "$1" "$2"
  else
    printf '%s' "$2"
  fi
}
info() { printf '%s %s\n' "$(_color '1;36' '[design-md]')" "$*"; }
warn() { printf '%s %s\n' "$(_color '1;33' '[design-md]')" "$*" >&2; }
err()  { printf '%s %s\n' "$(_color '1;31' '[design-md]')" "$*" >&2; }
ok()   { printf '%s %s\n' "$(_color '1;32' '[design-md]')" "$*"; }
