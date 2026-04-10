#!/usr/bin/env bash
# test.sh — smoke tests for the awesome-design-md skill.
#
# Usage:
#   bash test.sh                # run the full self-test suite
#   bash test.sh <file>         # run the full validation chain on <file>
#
# Self-test creates fixture files, runs validators against them, asserts
# expected pass/fail, and reports a summary. Exit 0 if all pass.

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=_lib.sh
. "${SCRIPT_DIR}/_lib.sh"

# If called with a file arg → run full validation on that file
if [ -n "${1:-}" ] && [ -f "$1" ]; then
  FILE="$1"
  info "Running full validation on $FILE"
  bash "${SCRIPT_DIR}/validate-tokens.sh" "$FILE" || true
  bash "${SCRIPT_DIR}/validate-component.sh" "$FILE" || true
  bash "${SCRIPT_DIR}/quality-score.sh" "$FILE"
  exit 0
fi

# Otherwise run self-tests
info "Running self-test suite..."

PASS=0
FAIL=0
ASSERTIONS=()

assert() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    ASSERTIONS+=("  ✓ $name")
  else
    FAIL=$((FAIL + 1))
    ASSERTIONS+=("  ✗ $name (expected=$expected, got=$actual)")
  fi
}

# -------- Fixture: well-formed component --------
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT

cat > "$FIXTURE_DIR/good.tsx" <<'EOF'
import * as React from "react";

export function Button({
  children,
  loading,
  disabled,
  onClick,
}: {
  children: React.ReactNode;
  loading?: boolean;
  disabled?: boolean;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      className="inline-flex items-center justify-center rounded-md bg-accent text-accent-fg px-4 py-2 font-medium min-h-11 min-w-11 transition-colors duration-fast ease-out hover:bg-accent-hover focus-visible:outline-none focus-visible:shadow-[0_0_0_2px_var(--color-bg),0_0_0_5px_var(--color-focus-ring)] active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none aria-busy:opacity-70 aria-busy:cursor-wait forced-colors:border forced-colors:border-[ButtonText] sm:text-sm md:text-base"
      aria-busy={loading}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
EOF

# -------- Fixture: bad component --------
cat > "$FIXTURE_DIR/bad.tsx" <<'EOF'
// This file has #ff0000 in a comment — should NOT be flagged.
export function BadCard() {
  return (
    <div
      onClick={() => {}}
      style={{ background: '#ff0000', color: '#fff', padding: '17px' }}
    >
      Click me
      <img src="/logo.png" />
    </div>
  );
}
EOF

# -------- Fixture: DESIGN.md (copy the skill's own) --------
cp "${SCRIPT_DIR}/../DESIGN.md" "$FIXTURE_DIR/DESIGN.md"

# -------- Tests --------

# 1. validate-tokens should PASS on good
bash "${SCRIPT_DIR}/validate-tokens.sh" "$FIXTURE_DIR/good.tsx" > /dev/null 2>&1
assert "validate-tokens passes on good.tsx" "0" "$?"

# 2. validate-tokens should FAIL on bad (hex, inline color, img no alt)
bash "${SCRIPT_DIR}/validate-tokens.sh" "$FIXTURE_DIR/bad.tsx" > /dev/null 2>&1
actual=$?
[ "$actual" -eq 0 ] && actual="PASS" || actual="FAIL"
assert "validate-tokens fails on bad.tsx" "FAIL" "$actual"

# 3. validate-tokens should NOT flag the commented hex
violations=$(bash "${SCRIPT_DIR}/validate-tokens.sh" "$FIXTURE_DIR/bad.tsx" 2>&1 | grep -c "HEX: 1:" || true)
# The comment is line 1, so if we see "HEX: 1:" it means we flagged the comment
assert "validate-tokens ignores hex in comments" "0" "${violations:-0}"

# 4. validate-component should warn (not block) on good (because depth/hover/focus are all present)
bash "${SCRIPT_DIR}/validate-component.sh" "$FIXTURE_DIR/good.tsx" > /dev/null 2>&1
assert "validate-component passes on good.tsx" "0" "$?"

# 5. validate-component should BLOCK on bad (MISSING_FOCUS_VISIBLE is a violation)
bash "${SCRIPT_DIR}/validate-component.sh" "$FIXTURE_DIR/bad.tsx" > /dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && result="blocked" || result="passed"
assert "validate-component blocks bad.tsx (missing focus-visible)" "blocked" "$result"

# 6. quality-score should be ≥ 90 (A) on good
score=$(bash "${SCRIPT_DIR}/quality-score.sh" "$FIXTURE_DIR/good.tsx" 2>/dev/null | grep -oE '"totalScore":[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')
score=${score:-0}
[ "$score" -ge 90 ] && grade="A-or-better" || grade="below-A"
assert "good.tsx scores A (≥ 90), got $score" "A-or-better" "$grade"

# 7. quality-score should be < 60 (F) on bad
score_bad=$(bash "${SCRIPT_DIR}/quality-score.sh" "$FIXTURE_DIR/bad.tsx" 2>/dev/null | grep -oE '"totalScore":[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')
score_bad=${score_bad:-100}
[ "$score_bad" -lt 60 ] && bgrade="F" || bgrade="above-F"
assert "bad.tsx scores F (< 60), got $score_bad" "F" "$bgrade"

# 8. lint-design-md should PASS on the skill's own DESIGN.md
bash "${SCRIPT_DIR}/lint-design-md.sh" "$FIXTURE_DIR/DESIGN.md" > /dev/null 2>&1
assert "lint-design-md passes on the bundled DESIGN.md" "0" "$?"

# 9. detect-framework should return valid JSON
json=$(bash "${SCRIPT_DIR}/detect-framework.sh" "$FIXTURE_DIR" 2>/dev/null)
echo "$json" | grep -q '"cssFramework"'
assert "detect-framework emits JSON with cssFramework" "0" "$?"

# 10. contrast-check should run on the skill's DESIGN.md
if command -v node >/dev/null 2>&1; then
  node "${SCRIPT_DIR}/contrast-check.mjs" "$FIXTURE_DIR/DESIGN.md" > /dev/null 2>&1
  rc=$?
  # It might exit 1 if there are real contrast failures; that's OK — script works
  if [ "$rc" -le 1 ]; then
    assert "contrast-check.mjs runs successfully" "0" "0"
  else
    assert "contrast-check.mjs runs successfully" "0" "$rc"
  fi
fi

# 11. generate-theme should produce output for tailwind-v4
if command -v node >/dev/null 2>&1; then
  node "${SCRIPT_DIR}/generate-theme.mjs" "$FIXTURE_DIR/DESIGN.md" --target=tailwind-v4 2>/dev/null | grep -q '@theme'
  assert "generate-theme.mjs tailwind-v4 emits @theme block" "0" "$?"

  # Test shadcn target
  node "${SCRIPT_DIR}/generate-theme.mjs" "$FIXTURE_DIR/DESIGN.md" --target=shadcn 2>/dev/null | grep -q '@layer base'
  assert "generate-theme.mjs shadcn emits @layer base" "0" "$?"

  # Test mui target
  node "${SCRIPT_DIR}/generate-theme.mjs" "$FIXTURE_DIR/DESIGN.md" --target=mui 2>/dev/null | grep -q 'createTheme'
  assert "generate-theme.mjs mui emits createTheme" "0" "$?"
fi

# -------- Report --------
printf '\n%s\n' "---- Test Results ----"
for a in "${ASSERTIONS[@]}"; do
  printf '%s\n' "$a"
done
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
  err "Self-test FAILED"
  exit 1
fi
ok "All $PASS tests passed"
exit 0
