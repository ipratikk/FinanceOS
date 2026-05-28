# Create PR

Orchestrates pull request creation with inline CI validation. Claude runs each step directly,
waits for the result, and fixes any failures before proceeding. Does not delegate to a script.

## Usage

- `/create-pr` — Full workflow
- `/create-pr --skipValidation` — Skip CI steps (only when already validated)
- `/create-pr --base=<branch>` — Stacked PR against a non-main branch

---

## Execution Flow

### Phase 0: Branch check (always runs)

Run:
```bash
git branch --show-current
```

Warn (do not block) if branch does not follow `<type>/<description>` convention.

---

### Phase 1: Identify changed files

Run:
```bash
git diff --name-only origin/main...HEAD
```

Use this list to determine:
- Which `.swift` files need linting
- Which packages under `Packages/` have changes and need tests run

Known packages:
- `Packages/FinanceCore`
- `Packages/FinanceParsers`
- `Packages/FinanceUI`
- `Packages/FinanceTesting`
- `Packages/FinanceIntelligence`

---

### Phase 2: SwiftLint (skip if `--skipValidation`)

For each changed `.swift` file, run:
```bash
swiftlint lint --strict --quiet --path <file>
```

**Rules:**
- Any `error:` output → fix the violation immediately, then re-lint that file until clean
- `warning:` output → fix it, warnings are not acceptable in PR
- Only proceed to Phase 3 once all changed files lint clean

---

### Phase 3: Package tests (skip if `--skipValidation`)

For each package that has changed files, run:
```bash
swift test --package-path Packages/<PackageName> --parallel
```

Wait for the full output.

**Rules:**
- Any test failure → read the failure output, fix the failing code, re-run tests for that package
- Only proceed to Phase 4 when all affected packages pass
- If a fix introduces changes in another package, re-lint and re-test that package too

---

### Phase 4: macOS build (skip if `--skipValidation`)

Run:
```bash
xcodebuild build \
  -workspace FinanceOS.xcworkspace \
  -scheme FinanceOSMac \
  -destination 'platform=macOS,arch=arm64' \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

**Rules:**
- `BUILD FAILED` or any `error:` line → fix the error, re-run build until `BUILD SUCCEEDED`
- Only proceed to Phase 5 after seeing `BUILD SUCCEEDED`

---

### Phase 5: Branch sync

Run:
```bash
git fetch origin main
git rev-list --count HEAD..origin/main
```

If behind → run `git pull --rebase origin main`, then push.

Run:
```bash
git push -u origin HEAD
```

---

### Phase 6: PR creation

Inspect commits on this branch vs `origin/main`:
```bash
git log origin/main..HEAD --oneline
```

Then create the PR:
```bash
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "$(cat <<'EOF'
## Summary
- <bullet points from commit messages>

## Test plan
- [ ] SwiftLint clean on all changed files
- [ ] Package tests pass (affected packages only)
- [ ] macOS build succeeded

## Notes
<migration notes, breaking changes, follow-ups if any>
EOF
)" \
  --base <base-branch>
```

Return the PR URL.

---

## Rules

- **Never create the PR if Phase 2, 3, or 4 produced any error or failure.**
- Fix failures inline. Do not ask "should I proceed anyway?" — fix, then proceed.
- `--skipValidation` is the only bypass. If the user did not pass it, run all phases.
