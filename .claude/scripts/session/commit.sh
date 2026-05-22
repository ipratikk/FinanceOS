#!/usr/bin/env bash
# commit.sh
# Group unstaged changes into logical commits by architecture layer.
# Uses caveman-commit for message generation.
# Prints a summary of created commits.
#
# Usage: commit.sh [--dry-run]
#
# Exit codes:
#   0 = commits created
#   1 = nothing to commit
#   2 = error

set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Abort if working tree is clean
if git diff --quiet && git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 1
fi

# Collect all modified files (unstaged + staged)
MODIFIED=$(git status --porcelain | awk '{print $2}' | sort -u)

if [ -z "$MODIFIED" ]; then
  echo "Nothing to commit."
  exit 1
fi

# ── Grouping logic by architecture layer ─────────────────────────────────────
# Each group: label + grep pattern against file path

declare -a GROUP_LABELS
declare -a GROUP_PATTERNS

GROUP_LABELS+=(  "parsers"        ); GROUP_PATTERNS+=(  "Packages/FinanceParsers"  )
GROUP_LABELS+=(  "finance-core"   ); GROUP_PATTERNS+=(  "Packages/FinanceCore"     )
GROUP_LABELS+=(  "finance-ui"     ); GROUP_PATTERNS+=(  "Packages/FinanceUI"       )
GROUP_LABELS+=(  "app"            ); GROUP_PATTERNS+=(  "FinanceOS/"               )
GROUP_LABELS+=(  "claude-config"  ); GROUP_PATTERNS+=(  "\.claude/"                )
GROUP_LABELS+=(  "scripts"        ); GROUP_PATTERNS+=(  "Scripts/"                 )
GROUP_LABELS+=(  "tests"          ); GROUP_PATTERNS+=(  "Tests/"                   )
GROUP_LABELS+=(  "misc"           ); GROUP_PATTERNS+=(  "."                        )  # catch-all

CREATED_COMMITS=()
ALREADY_STAGED=()

for i in "${!GROUP_LABELS[@]}"; do
  label="${GROUP_LABELS[$i]}"
  pattern="${GROUP_PATTERNS[$i]}"

  # Files in this group that are modified and not yet committed
  group_files=()
  while IFS= read -r f; do
    # Skip already staged in a prior group
    skip=0
    for s in "${ALREADY_STAGED[@]+"${ALREADY_STAGED[@]}"}"; do
      [ "$s" = "$f" ] && skip=1 && break
    done
    [ "$skip" -eq 1 ] && continue
    group_files+=("$f")
  done < <(echo "$MODIFIED" | grep -E "$pattern" || true)

  [ "${#group_files[@]}" -eq 0 ] && continue

  echo ""
  echo "── Group: $label ──────────────────────────────────"
  printf "  %s\n" "${group_files[@]}"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run: would commit ${#group_files[@]} files]"
    ALREADY_STAGED+=("${group_files[@]}")
    continue
  fi

  # Stage group files
  git add -- "${group_files[@]}"

  # Generate commit message via claude, fall back to generic
  if command -v claude &>/dev/null; then
    diff_summary=$(git diff --cached --stat 2>/dev/null | tail -5)
    diff_patch=$(git diff --cached 2>/dev/null | head -200)
    prompt="Write a git commit message for these changes. Conventional Commits format. Subject ≤50 chars. Body only if why is non-obvious. No filler. Layer: $label.\n\nStat:\n$diff_summary\n\nDiff:\n$diff_patch"
    msg=$(echo -e "$prompt" | claude -p --output-format text 2>/dev/null | head -20 || echo "chore($label): update ${#group_files[@]} file(s)")
  else
    msg="chore($label): update ${#group_files[@]} file(s)"
  fi

  git commit -m "$msg" --quiet
  sha=$(git rev-parse --short HEAD)
  CREATED_COMMITS+=("[$sha] $msg")
  ALREADY_STAGED+=("${group_files[@]}")
done

echo ""
echo "── Created Commits ──────────────────────────────────"
if [ "${#CREATED_COMMITS[@]}" -eq 0 ]; then
  echo "  (none — dry-run or nothing grouped)"
else
  for c in "${CREATED_COMMITS[@]}"; do
    echo "  $c"
  done
fi
