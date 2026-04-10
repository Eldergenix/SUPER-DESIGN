#!/usr/bin/env bash
# detect-framework.sh — identifies CSS framework, component library, project type, DESIGN.md
#
# Output: JSON to stdout with detected project characteristics.
# Usage:  bash detect-framework.sh [project-root]

set -eo pipefail

ROOT="${1:-$PWD}"
cd "$ROOT"

out() {
  printf '%s' "$1"
}

has_file() {
  [ -e "$1" ] && return 0 || return 1
}

pkg_has() {
  [ -f package.json ] || return 1
  grep -q "\"$1\"" package.json 2>/dev/null
}

grep_css() {
  local pattern="$1"
  find . \
    -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next \) -prune -o \
    -type f \( -name '*.css' -o -name '*.scss' \) -print 2>/dev/null \
    | head -50 \
    | xargs grep -l -E "$pattern" 2>/dev/null \
    | head -1
}

# ---------- CSS framework ----------
css_framework="none"
tw_version="none"

if [ -f package.json ]; then
  if pkg_has '@tailwindcss/postcss' || pkg_has '@tailwindcss/vite'; then
    css_framework="tailwind"
    tw_version="v4"
  elif pkg_has 'tailwindcss'; then
    # Check version
    tw_ver=$(grep -oE '"tailwindcss"\s*:\s*"\^?[0-9]+' package.json | grep -oE '[0-9]+$' | head -1)
    if [ "$tw_ver" = "4" ]; then
      css_framework="tailwind"; tw_version="v4"
    elif [ "$tw_ver" = "3" ]; then
      css_framework="tailwind"; tw_version="v3"
    else
      css_framework="tailwind"; tw_version="unknown"
    fi
  fi
fi

# Confirm v4 by CSS markers (overrides version if found)
if [ "$css_framework" = "tailwind" ]; then
  if [ -n "$(grep_css '@import[[:space:]]+"tailwindcss"')" ] || \
     [ -n "$(grep_css '@theme[[:space:]]*\{')" ]; then
    tw_version="v4"
  elif [ -n "$(grep_css '@tailwind[[:space:]]+base')" ]; then
    tw_version="v3"
  fi
fi

# ---------- Component library ----------
library="none"

if has_file components.json && pkg_has 'class-variance-authority' && pkg_has 'tailwind-merge'; then
  library="shadcn"
elif pkg_has '@mui/material'; then
  library="mui"
elif pkg_has '@radix-ui/themes'; then
  library="radix-themes"
elif [ -f package.json ] && grep -q '"@radix-ui/react-' package.json 2>/dev/null; then
  library="radix-primitives"
elif pkg_has '@geist-ui/core' || pkg_has '@vercel/geist-ui'; then
  library="geist-ui"
elif pkg_has 'geist'; then
  library="geist-font"
fi

# ---------- Project framework ----------
project="unknown"

if pkg_has 'next'; then
  project="nextjs"
elif pkg_has '@remix-run/'; then
  project="remix"
elif pkg_has 'astro'; then
  project="astro"
elif pkg_has '@sveltejs/kit'; then
  project="sveltekit"
elif pkg_has 'vite'; then
  project="vite"
elif pkg_has 'react-scripts'; then
  project="cra"
elif has_file index.html; then
  project="static"
fi

# ---------- DESIGN.md ----------
design_md_path=""
if [ -f DESIGN.md ]; then
  design_md_path="DESIGN.md"
elif [ -f docs/DESIGN.md ]; then
  design_md_path="docs/DESIGN.md"
elif [ -f .github/DESIGN.md ]; then
  design_md_path=".github/DESIGN.md"
fi

# ---------- AGENTS.md ----------
agents_md_path=""
[ -f AGENTS.md ] && agents_md_path="AGENTS.md"

# ---------- Entry stylesheet ----------
globals_css=""
for candidate in app/globals.css src/app/globals.css src/globals.css styles/globals.css app/styles.css src/styles.css src/index.css src/main.css; do
  if [ -f "$candidate" ]; then
    globals_css="$candidate"
    break
  fi
done

# ---------- Emit JSON ----------
cat <<EOF
{
  "root": "$ROOT",
  "cssFramework": "$css_framework",
  "tailwindVersion": "$tw_version",
  "componentLibrary": "$library",
  "projectFramework": "$project",
  "designMd": "$design_md_path",
  "agentsMd": "$agents_md_path",
  "globalsCss": "$globals_css",
  "recommendedAdapter": "$( \
    case "$library" in
      shadcn)           echo "shadcn" ;;
      mui)              echo "mui" ;;
      radix-themes)     echo "radix" ;;
      radix-primitives) echo "${tw_version}-with-radix" ;;
      geist-ui|geist-font) echo "geist" ;;
      *)                echo "$tw_version" ;;
    esac )"
}
EOF
