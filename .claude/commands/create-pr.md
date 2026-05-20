# Create PR

Orchestrates pull request creation with local CI validation before pushing.

## Usage

- `/create-pr` — Full workflow
- `/create-pr --skipValidation` — Skip local CI (use only when CI already passed on a prior push)
- `/create-pr --base=<branch>` — Stacked PR against a non-main branch

## Options

- **`--skipValidation`** — Skip `pre-pr.sh` (branch already validated or trivial change)
- **`--base=<branch>`** — Target branch for stacked PRs (default: `main`)

## Execution Flow

### Phase 0: Branch naming check (always runs)

Verify branch follows `<type>/<description>` convention:
- ✓ `fix/fds-tokens`, `feat/parser-hdfc`, `refactor/ledger-model`
- ✗ `my-branch`, `test`, bare `main`

Warn but do not block on mismatch.

### Phase 1: Local CI validation (unless `--skipValidation`)

```bash
.claude/scripts/validate/pre-pr.sh
```

Mirrors `.github/workflows/swift.yml` — runs in order:
1. **SwiftLint** — strict mode on changed files vs `origin/main`
2. **Package tests** — `swift test --parallel` for each affected package
3. **macOS build** — `xcodebuild -scheme FinanceOSMac -quiet`

If any step fails → stop, report, ask:
> "Fix before creating PR? (yes/no)"
- Yes → pause and wait for user to fix, then re-run validation
- No → proceed at user's risk

### Phase 2: Branch sync check

```bash
git fetch origin main
git rev-list --count HEAD..origin/main
```

If behind → rebase: `git pull --rebase origin main`, then push branch.

### Phase 3: PR creation

```bash
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "$(cat <<'EOF'
## Summary
- <what changed>
- <why>

## Test plan
- [ ] Local CI passed (`pre-pr.sh`)
- [ ] Manual smoke test on affected screens
- [ ] Parser tests (`/parser-test`) — if parsers touched

## Notes
<migration notes, breaking changes, follow-ups>
EOF
)" \
  --base <base-branch>
```

**Title format:** matches conventional commit style — `fix(parser): handle HDFC date format`

Return the PR URL when done.
