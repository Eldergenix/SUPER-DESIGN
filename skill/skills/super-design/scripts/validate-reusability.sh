#!/usr/bin/env bash
# validate-reusability.sh — enforces component reusability rules.
# Runs as PostToolUse hook on Edit|Write|MultiEdit, or manually.
#
# A "reusable" component in this skill's sense is one that:
#   1. Has an exported Props type/interface (so callers can depend on its shape)
#   2. Has a clear single primary export (no grab-bag files)
#   3. Doesn't hardcode the content that makes it unique — that content
#      comes from props or children
#   4. Doesn't fetch or compute data at module scope — that's caller's job
#
# Unlike validate-component.sh (which is about quality: state coverage,
# responsive, touch targets), this script is about *shape*: can someone
# drop this component into a different context and parameterize it?
#
# Usage:
#   bash validate-reusability.sh <file>            (manual)
#   echo '{"tool_input":{"file_path":"..."}}' | bash validate-reusability.sh  (hook)
#
# Exit codes:
#   0  — pass (possibly with non-blocking warnings)
#   2  — block (hook) / 1 (manual) — violations present

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

FILE_PATH=""
IS_HOOK=0

if [ -n "${1:-}" ]; then
  FILE_PATH="$1"
else
  IS_HOOK=1
  PAYLOAD=$(cat 2>/dev/null || printf '{}')
  FILE_PATH=$(read_json_field "$PAYLOAD" '.tool_input.file_path')
fi

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Only check JSX/TSX/Vue/Svelte component files
case "$FILE_PATH" in
  *.tsx|*.jsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac

should_skip_file "$FILE_PATH" && exit 0

# Exempt: page/route files, entry points, story files, test files.
# Pages are the one place where hardcoded content is correct.
case "$FILE_PATH" in
  */pages/*|*/app/*/page.tsx|*/app/*/layout.tsx|*/routes/*|*/main.tsx|*/main.jsx|*/App.tsx|*/App.jsx|*/index.tsx|*/index.jsx|*.stories.tsx|*.stories.jsx|*.test.tsx|*.test.jsx|*.spec.tsx|*.spec.jsx|*/[Dd]esign[Ss]ystem.tsx|*/design-system/*)
    exit 0 ;;
esac

WARNINGS=()
VIOLATIONS=()

TMP_CLEAN=$(mktemp)
trap 'rm -f "$TMP_CLEAN"' EXIT
strip_comments "$FILE_PATH" > "$TMP_CLEAN"

# -------- Skip empty files --------
LOC=$(awk 'NF' "$TMP_CLEAN" 2>/dev/null | wc -l | tr -d '[:space:]')
LOC=${LOC:-0}
[ "$LOC" -lt 5 ] && exit 0

# -------- Is this a component file? (heuristic) --------
# A component has at least one PascalCase function/const export that returns JSX.
HAS_COMPONENT=0
if grep -qE '^[[:space:]]*(export[[:space:]]+(default[[:space:]]+)?)?(function|const)[[:space:]]+[A-Z][A-Za-z0-9_]*' "$TMP_CLEAN" 2>/dev/null; then
  if grep -qE '(return[[:space:]]*\(|=>[[:space:]]*\()' "$TMP_CLEAN" 2>/dev/null && grep -qE '<[A-Za-z]' "$TMP_CLEAN" 2>/dev/null; then
    HAS_COMPONENT=1
  fi
fi
[ "$HAS_COMPONENT" -eq 0 ] && exit 0

# -------- 1. Props interface/type presence --------
# For TSX files, a reusable component should declare a Props shape.
# Accepted forms:
#   interface ButtonProps { ... }
#   type ButtonProps = { ... }
#   export interface ButtonProps { ... }
#   export type ButtonProps = { ... }
#   function Button({ ... }: ButtonProps) { ... }
#   function Button(props: ButtonProps) { ... }
#   function Button({ ... }: { ...inline... }) { ... }          (inline OK but warns)
#   function Button() { return ... }                              (zero props OK)
case "$FILE_PATH" in
  *.tsx)
    HAS_PROPS_INTERFACE=0
    HAS_INLINE_PROPS=0
    HAS_ZERO_PROPS=0

    if grep -qE '(^|[[:space:]])(interface|type)[[:space:]]+[A-Z][A-Za-z0-9_]*Props\b' "$TMP_CLEAN" 2>/dev/null; then
      HAS_PROPS_INTERFACE=1
    fi

    if grep -qE ':[[:space:]]*\{[[:space:]]*[a-zA-Z_][^}]*\}[[:space:]]*\)' "$TMP_CLEAN" 2>/dev/null; then
      HAS_INLINE_PROPS=1
    fi

    # A zero-props component — `function Foo() {` with no args between parens.
    if grep -qE '(function|const)[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*(=[[:space:]]*\(\)|[[:space:]]*\(\))' "$TMP_CLEAN" 2>/dev/null; then
      HAS_ZERO_PROPS=1
    fi

    if [ "$HAS_PROPS_INTERFACE" -eq 0 ] && [ "$HAS_ZERO_PROPS" -eq 0 ]; then
      if [ "$HAS_INLINE_PROPS" -eq 1 ]; then
        WARNINGS+=("NO_PROPS_INTERFACE: component uses inline props shape — extract a named interface or type so callers can import the type")
      else
        WARNINGS+=("NO_PROPS_INTERFACE: no named Props interface/type found — declare one (e.g. 'interface ButtonProps { ... }') so callers can depend on the shape")
      fi
    fi

    # Props interface should be exported so consumers can import it.
    if [ "$HAS_PROPS_INTERFACE" -eq 1 ]; then
      if ! grep -qE '^[[:space:]]*export[[:space:]]+(interface|type)[[:space:]]+[A-Z][A-Za-z0-9_]*Props\b' "$TMP_CLEAN" 2>/dev/null; then
        WARNINGS+=("PROPS_NOT_EXPORTED: Props interface is declared but not exported — add 'export' so consumers can import the type")
      fi
    fi
    ;;
esac

# -------- 2. Hardcoded long content strings in JSX --------
# A reusable component shouldn't hardcode paragraph-length content that
# makes it unique to one use site. Short labels (≤40 chars) are fine.
# Flags JSX children that are string literals longer than the threshold.
LONG_STRINGS=$(grep -nE '>[^<{}]{60,}<' "$TMP_CLEAN" 2>/dev/null \
  | grep -vE '(https?://|mailto:|tel:|example\.|lorem)' \
  | head -5)
if [ -n "$LONG_STRINGS" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    WARNINGS+=("HARDCODED_CONTENT: $line — extract long strings into props or children for reusability")
  done <<< "$LONG_STRINGS"
fi

# -------- 3. Top-level hardcoded data arrays/objects --------
# A component that exports a named array of records is probably a page,
# not a component. Flag large module-scope arrays.
MODULE_DATA=$(grep -nE '^(const|let|var)[[:space:]]+[a-z][A-Za-z0-9_]*[[:space:]]*(:[[:space:]]*[A-Za-z<>[\],[:space:]|]+)?[[:space:]]*=[[:space:]]*\[' "$TMP_CLEAN" 2>/dev/null | head -5)
if [ -n "$MODULE_DATA" ]; then
  # Count how many items are inside any such array — >3 items warns
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    line_no=${line%%:*}
    # Count commas+braces in the next 30 lines as a proxy for item count
    end=$((line_no + 30))
    items=$(sed -n "${line_no},${end}p" "$TMP_CLEAN" 2>/dev/null | grep -cE '^\s*\{' || echo 0)
    if [ "$items" -gt 3 ]; then
      WARNINGS+=("MODULE_DATA: hardcoded data array at line $line_no ($items items) — accept this as a prop so the component is reusable")
    fi
  done <<< "$MODULE_DATA"
fi

# -------- 4. Data fetching inside component --------
# fetch(), axios.*, useQuery(), useSWR() in a component file means the
# component is coupled to a specific API. Reusable components accept
# data via props; data fetching belongs in containers/hooks.
if grep -qE '\bfetch\s*\(|\baxios\.|useQuery\s*\(|useSWR\s*\(|useMutation\s*\(' "$TMP_CLEAN" 2>/dev/null; then
  # Allow if file is in a /containers/ or /hooks/ folder (conventional home for fetching)
  case "$FILE_PATH" in
    */containers/*|*/hooks/*|*/pages/*|*/routes/*|*/app/*)
      ;;
    *)
      WARNINGS+=("COMPONENT_FETCHES: component fetches data directly (fetch/axios/useQuery/useSWR) — move data fetching into a container or hook, pass data via props")
      ;;
  esac
fi

# -------- 5. Single-primary-export rule --------
# A component file should export ONE primary component. Multiple
# unrelated component exports in one file hurts reusability because
# you can't tree-shake and the file's "purpose" becomes ambiguous.
#
# Uses count_matches (from _lib.sh) instead of `grep -c` because grep -c
# prints "0" and exits 1 on no-match, which combined with `|| echo 0`
# produces multi-line output "0\n0" that breaks arithmetic. count_matches
# always returns a clean integer.
NAMED_EXPORTS=$(count_matches '^export[[:space:]]+(function|const|class)[[:space:]]+[A-Z]' "$TMP_CLEAN")
HAS_DEFAULT=$(count_matches '^export[[:space:]]+default' "$TMP_CLEAN")
TOTAL_COMPONENT_EXPORTS=$((NAMED_EXPORTS + HAS_DEFAULT))
if [ "$TOTAL_COMPONENT_EXPORTS" -gt 2 ]; then
  WARNINGS+=("MULTI_PRIMARY: $TOTAL_COMPONENT_EXPORTS component-like exports in one file — split into separate files (one component per file for tree-shaking + discoverability)")
fi

# -------- 6. children prop usage or prop count --------
# A truly flexible component either accepts children OR accepts enough
# props to be parameterized. If we see a JSX body with no {children}
# reference AND no destructured props, that's a strong hint the component
# hardcodes its own content.
HAS_CHILDREN=$(count_matches '\bchildren\b' "$TMP_CLEAN")
HAS_PROP_DESTRUCTURE=$(count_matches 'function[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*\([[:space:]]*\{|const[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*\([[:space:]]*\{' "$TMP_CLEAN")
if [ "$HAS_CHILDREN" -eq 0 ] && [ "$HAS_PROP_DESTRUCTURE" -eq 0 ] && [ "$LOC" -gt 30 ]; then
  WARNINGS+=("NO_PARAMETERIZATION: component has no {children} usage and no destructured props — the content is hardcoded and can't be reused. Accept children or add props.")
fi

# -------- Report --------
V=${#VIOLATIONS[@]}
W=${#WARNINGS[@]}

MSG="reusability audit: ${FILE_PATH} (LOC=$LOC)"$'\n'

if [ "$V" -gt 0 ]; then
  MSG+=$'\n'"❌ $V violation(s):"$'\n'
  for v in "${VIOLATIONS[@]}"; do MSG+="  • $v"$'\n'; done
fi
if [ "$W" -gt 0 ]; then
  MSG+=$'\n'"⚠ $W warning(s):"$'\n'
  for w in "${WARNINGS[@]}"; do MSG+="  • $w"$'\n'; done
fi

if [ "$V" -eq 0 ] && [ "$W" -eq 0 ]; then
  [ "$IS_HOOK" -eq 0 ] && ok "$FILE_PATH — reusability audit passed"
  exit 0
fi

if [ "$V" -gt 0 ]; then
  if [ "$IS_HOOK" -eq 1 ]; then
    printf '%s\n' "$MSG" >&2
    exit 2
  else
    printf '%s\n' "$MSG"
    exit 1
  fi
else
  if [ "$IS_HOOK" -eq 1 ]; then
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$MSG" | jq -Rs '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: .}}'
    else
      esc=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')
      printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
    fi
  else
    printf '%s\n' "$MSG"
  fi
  exit 0
fi
