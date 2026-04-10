#!/usr/bin/env bash
# audit.sh — batch style audit across a directory.
# Walks every component file, runs quality-score.sh, sorts worst-first.
#
# Usage: bash audit.sh [path=src]
# Emits: JSON array on stdout (use with jq to slice), human summary on stderr.

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

TARGET="${1:-src}"
if [ ! -d "$TARGET" ]; then
  err "Directory not found: $TARGET"
  exit 2
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# Collect all auditable files
FILES=()
while IFS= read -r -d '' f; do
  should_skip_file "$f" && continue
  FILES+=("$f")
done < <(find "$TARGET" \
  -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name out -o -name .turbo -o -name coverage \) -prune -o \
  -type f \( -name '*.tsx' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' \) -print0 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
  warn "No auditable component files found in $TARGET"
  printf '[]\n'
  exit 0
fi

info "Scoring ${#FILES[@]} files..."

RESULTS=()
for f in "${FILES[@]}"; do
  result=$(bash "${SCRIPT_DIR}/quality-score.sh" "$f" 2>/dev/null || true)
  [ -z "$result" ] && continue
  RESULTS+=("$result")
done

# Emit JSON array
printf '%s' "["
first=1
for r in "${RESULTS[@]}"; do
  [ "$first" -eq 0 ] && printf ','
  printf '\n  %s' "$(echo "$r" | tr -d '\n')"
  first=0
done
printf '\n]\n'

# Human summary on stderr — sort by score ascending (worst first)
{
  echo ""
  echo "---- Audit Summary (worst first) ----"
  for r in "${RESULTS[@]}"; do
    score=$(echo "$r" | grep -oE '"totalScore":[[:space:]]*[0-9]+' | grep -oE '[0-9]+$' | head -1)
    grade=$(echo "$r" | grep -oE '"grade":[[:space:]]*"[A-F]"' | grep -oE '"[A-F]"' | tr -d '"' | head -1)
    file=$(echo "$r" | grep -oE '"file":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file":[[:space:]]*"//;s/"//')
    printf "%3d  %s  %s\n" "${score:-0}" "${grade:-?}" "${file:-?}"
  done | sort -n
} >&2
