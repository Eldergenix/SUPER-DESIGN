# Contributing to Super Design

Thanks for your interest in improving this skill. A few ground rules.

## Ground rules

1. **All PRs must pass `bash skills/super-design/scripts/test.sh`.** The self-test suite asserts every script against good/bad fixtures. Zero failures.
2. **All new validator logic must have a fixture test.** If you add a new rule to `validate-tokens.sh`, add a component fixture in `test.sh` that exercises it.
3. **Never introduce the `|| echo 0` anti-pattern.** Use `grep -oE ... | wc -l` for counts (see `_lib.sh` `count_matches`).
4. **Never interpolate shell variables into Python/JS strings** in hook scripts — use `jq` with stdin or `python3 -c` reading from stdin. See `inject-design-context.sh` as the reference.
5. **All paths must be double-quoted.** The installer and scripts must handle spaces in project paths.
6. **Exclude `.git`, `.DS_Store`, `node_modules`, `__pycache__`** on any copy or find operation.

## Development workflow

```bash
# Clone & test
git clone <repo>
cd skill
bash skills/super-design/scripts/test.sh     # must pass

# Install into a sample project for manual validation
mkdir /tmp/sample && cd /tmp/sample
PROJECT_ROOT=$PWD bash /path/to/skill/install.sh --project --dry-run   # preview
PROJECT_ROOT=$PWD bash /path/to/skill/install.sh --project             # actual
bash .claude/skills/super-design/scripts/lint-design-md.sh DESIGN.md
node .claude/skills/super-design/scripts/contrast-check.mjs DESIGN.md
node .claude/skills/super-design/scripts/generate-theme.mjs DESIGN.md --target=tailwind-v4
```

## Code style

### Shell scripts
- Source `_lib.sh` for shared helpers (`count_matches`, `strip_comments`, `read_json_field`, `jsx_max_depth`, `should_skip_file`, `is_auditable_file`, color/log helpers).
- Use `set +e` for scripts with many grep-predicate patterns (reporting scripts).
- Use `set -eo pipefail` for scripts where every command must succeed (installers).
- Quote every variable: `"$FILE_PATH"`, not `$FILE_PATH`.
- Use `[ ]` (POSIX) not `[[ ]]` (bashism) where possible; if you need bashisms, document it.
- Graceful JSON handling: prefer `jq`, fall back to `python3`, fall back to shell.
- No `echo -e`, no `echo -n` — use `printf`.

### JavaScript
- ESM (`import`) not CJS.
- Node 18+.
- No external deps in the hot path — `contrast-check.mjs`, `generate-theme.mjs`, `visual-diff.mjs` all work with only Node built-ins plus `optionalDependencies` (`odiff-bin`, `pixelmatch`, `playwright`).
- Error messages go to `stderr`, data to `stdout`, JSON reports to named files.

### Markdown (references/)
- Concrete code blocks beat prose.
- Every reference doc stays under 1000 words.
- Use tables for token maps and state matrices.
- Include source URLs for claims about frameworks.

## Adding a new framework adapter

1. Create `references/framework-adapters/<name>.md` with:
   - Detection rules (package.json/config files)
   - Complete theme template (copy-paste ready)
   - Token mapping table (DESIGN.md → framework-native)
2. Add detection to `scripts/detect-framework.sh` → `recommendedAdapter` output.
3. Add codegen case to `scripts/generate-theme.mjs` → `emit<Name>()` function.
4. Add a test in `scripts/test.sh` that the generator emits valid output.
5. Update `CHANGELOG.md`.

## Adding a new hook rule

1. Add the check to `validate-tokens.sh` or `validate-component.sh`.
2. Add a matching rule to `templates/configs/.eslintrc.design-md.json` or `.stylelintrc.design-md.json` so projects without hooks still catch it at commit time.
3. Add a fixture to `scripts/test.sh`:
   ```bash
   cat > "$FIXTURE_DIR/new-rule-bad.tsx" <<'EOF'
   <!-- demonstrates the violation -->
   EOF
   bash "${SCRIPT_DIR}/validate-tokens.sh" "$FIXTURE_DIR/new-rule-bad.tsx" > /dev/null 2>&1
   assert "validate-tokens flags <rule>" "FAIL" "$(...)"
   ```
4. Document the rule in `references/component-quality-gates.md`.
5. Update `CHANGELOG.md`.

## Security

- No network access from hooks or validators — everything is local file I/O.
- No shell exec of user-supplied data.
- No writing outside the project root (except `~/.claude/skills/` on global install).
- `curl | bash` install is NOT supported — users must clone or `npx`.

## Release process

1. Update `CHANGELOG.md` with new version.
2. Bump version in `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and the `INSTALLER_VERSION` constant in `scripts/install.sh`.
3. Run `bash skills/super-design/scripts/test.sh` — must be green.
4. Tag the release: `git tag v1.x.y && git push --tags`.
5. Publish to npm: `npm publish` (from the `skill/` directory).

## Questions

Open an issue at https://github.com/Eldergenix/SUPER-DESIGN/issues.
