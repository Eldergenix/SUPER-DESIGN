#!/usr/bin/env bash
# install.sh — one-shot installer that calls the skill's own installer.
# Run from the repo root (or `curl | bash` after pinning a tag).

set -eo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
exec bash "$SCRIPT_DIR/skills/super-design/scripts/install.sh" "$@"
