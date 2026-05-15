# Commit Skill

Create clean, minimal, architecture-aware git commits from unstaged changes.

Act like a senior engineer maintaining a long-term production codebase.

Primary goals:

* logical commit grouping
* minimal token usage
* architecture-aware separation
* clean git history
* small reviewable commits

---

# Execution Mode

You are allowed to execute git commands directly when the user asks to commit changes.

When creating commits:

* stage files yourself
* run caveman-commit yourself
* create commits yourself
* do not stop at suggesting commands

Only ask for confirmation if:

* changes appear destructive
* unrelated modifications are heavily mixed together
* sensitive/generated files may be committed
* commit grouping is ambiguous

Otherwise:

* perform logical commit grouping autonomously
* create commits directly

---

# Workflow

Before doing anything:

```bash id="v2k4xz"
git status
git diff --stat
git diff
```

Inspect ONLY changed files.

Do NOT scan unrelated repository files.

Use diffs as primary context.

---

# Commit Strategy

Break unstaged changes into logical commits.

Each commit should represent:

* one vertical slice
* one architectural concern
* one cohesive feature/fix

Prefer:

* small focused commits
* reviewable diffs
* architecture-aligned grouping

Avoid:

* giant mixed commits
* unrelated file grouping
* noisy formatting-only commits mixed with logic changes
* WIP-style commits

---

# Grouping Heuristics

Group changes by:

* feature
* architecture layer
* module
* dependency boundary
* parser/persistence/UI separation

GOOD examples:

* import parser changes
* parser models
* import preview UI
* repository additions
* migration changes

BAD examples:

* mixing parser logic + unrelated UI cleanup
* combining migrations + redesigns
* combining refactors + feature work

---

# Architecture Awareness

Preserve architecture boundaries:

SwiftUI View
→ ViewModel
→ Service
→ Repository
→ GRDB
→ SQLite

Do NOT combine unrelated layers unless part of the same vertical slice.

Default assumption:

* existing architecture decisions are intentional unless evidence suggests otherwise

Prefer extending current patterns over introducing new ones.

---

# Commit Message Generation

Use `caveman-commit` for generating commit messages.

Do NOT manually invent commit messages unless explicitly requested.

Workflow for each commit:

1. Stage only relevant files:

```bash id="a8m1kp"
git add <files>
```

2. Generate commit message:

```bash id="z5n7vd"
caveman-commit
```

3. Review generated message for:

* correctness
* scope accuracy
* architecture relevance
* concise wording

4. Create commit.

---

# Token Efficiency Rules

Do NOT:

* summarize unchanged files
* explain obvious diffs
* reread unrelated modules
* restate large code blocks
* generate verbose architectural essays

Prefer:

* concise reasoning
* direct commit grouping
* focused staging
* incremental commits

---

# Refactor Rules

Separate these into distinct commits whenever practical:

* refactors
* renames
* formatting
* behavior changes
* dependency changes

Avoid mixing mechanical and behavioral changes.

---

# Safety Rules

Before committing:

* identify accidental/debug/temp changes
* identify generated files
* identify unrelated modifications

Avoid committing:

* debug prints
* temporary logs
* derived/generated artifacts
* experiments
* unrelated local changes

Call out suspicious changes before committing.

---

# Commit Execution Rules

For each logical commit:

1. Identify cohesive file group
2. Stage only those files
3. Run:

```bash id="t4r7qn"
caveman-commit
```

4. Create commit
5. Continue until remaining unstaged changes are logically separated

Avoid:

* giant commits
* unrelated staging
* unnecessary confirmation prompts

After completion:

* provide concise summary of created commits only

---

# Response Format

After commits are completed, return ONLY:

## Created Commits

* <commit summary>
* <commit summary>
* <commit summary>

Keep responses concise and implementation-focused.
