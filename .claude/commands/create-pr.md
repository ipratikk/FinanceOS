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

Create a new branch from latest origin/main
Block if branch does not follow `<type>/<description>(<jira>)` convention.
Find jira for the current task and add it to the branchname

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

Run SwiftLint across the whole repo (do NOT use `--path <file>` — it bypasses the config):
```bash
swiftlint lint --strict --quiet 2>&1
```

**Rules:**
- Any `error:` or `warning:` line → fix the violation, then re-run until output is empty
- Only proceed to Phase 3 when `swiftlint lint --strict --quiet` produces zero output
- SwiftFormat and SwiftLint may conflict — run `swiftlint --fix --quiet` first to auto-fix trivial violations, then address remaining manually

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

Extract JIRA key and GitHub issue # from commits/branch.

Create PR with title format `<type>(<scope>): <description> (<jira>)`:
```bash
gh pr create \
  --title "<type>(<scope>): <description> (<jira>)" \
  --body "$(cat .github/PULL_REQUEST_TEMPLATE.md)" \
  --base <base-branch>
```

**Body must follow** [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md):
- Fill all Tracking fields (JIRA Issue, GitHub Issue)
- Select Type of Change
- List Changes Made with reasons
- Complete Test Plan checklist
- Document Architecture & Design impact
- Verify Checklist items
- Add Notes for reviewers

Return the PR URL.

---

## Rules

- **Never create the PR if Phase 2, 3, or 4 produced any error or failure.**
- Fix failures inline. Do not ask "should I proceed anyway?" — fix, then proceed.
- `--skipValidation` is the only bypass. If the user did not pass it, run all phases.
