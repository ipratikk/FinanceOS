Goal: Full phased stabilization of FinanceOS with zero ignored issues

Stabilize FinanceOS by moving through a strict sequence of phases where each phase first discovers every bug, warning, failing test, compile error, lint issue, mismatch, and behavioral inconsistency in that phase, then resolves all of them before any later phase begins.

The work must preserve the repo’s intended architecture: SwiftUI views go through ViewModels, ViewModels go through repository protocols, repositories own GRDB/SQLite access, and the parser layer remains isolated from UI and persistence.

Snapshot image recording and snapshot baseline updates are deferred until the final phase. However, snapshot test code is still production-quality code: compile errors, type errors, broken helpers, bad mocks, lint issues, stale APIs, or incorrect test fixtures inside snapshot test code must be fixed immediately when encountered. Only snapshot image generation/recording itself is deferred.

Non-negotiable execution rules
No phase may complete with unresolved errors, warnings, failing unit tests, compile failures, lint failures, analyzer warnings, or known behavioral bugs.
Do not suppress, skip, delete, or weaken tests to make the build pass. Fix the underlying issue.
Do not hide problems with try?, silent fallbacks, broad catch, default values, force unwraps, or warning-suppression flags.
Every bug fixed must be guarded by a unit test unless it is purely mechanical, such as a rename or formatting-only change.
Unit tests must reflect real-world financial behavior, not just the current implementation.
Parser tests must use realistic statement rows and edge cases, especially refunds, credits, duplicate descriptions, date formats, malformed rows, and quoted CSV content.
Snapshot baseline recording is skipped until the final phase, but snapshot test source code must continue to compile and remain clean.
Do not move to the next phase until the current phase has a clean validation gate.
Starting known issue inventory

These are the first issues that should be treated as already known and must be verified/fixed during the relevant phases.

Known P0 issues
1. Debit/credit analytics mismatch

Parsed transactions are mapped into stored transactions using absolute amountMinorUnits plus transactionType. But GRDBSpendingService classifies debit/credit using whether amountMinorUnits is negative. This can make dashboard totals wrong.

2. Auto-target matching can select the wrong ledger

AccountMatcher calculates targetBankName, but its exact-match path does not actually verify the bank; it checks kind, last4, and a non-optional bankId. ImportTargetMatcher has a safer bank-aware matching flow and should become the canonical path.

3. Deduplication schema/docs mismatch

Architecture docs describe deterministic deduplication via a composite unique index on (ledgerId, sourceFingerprint). The actual transaction table defines sourceFingerprint as globally unique by itself.

4. Import can silently default to bank account

During import, when the selected ledger ID cannot be found, the code defaults the ledger kind to .bankAccount. This must become a hard error.

5. Closing-balance update failure is swallowed

Closing-balance persistence after import uses try?, which can silently ignore failures. This must be made explicit.

6. Parser support is overstated

The README advertises CSV/XLSX support and multiple Indian banks. But the active file type detector only recognizes .csv and .txt. The active StatementSource enum exposes HDFC bank/card, ICICI bank/card, and Amex.

7. Parser tests are currently too thin

The visible parser package test only checks that HDFCPDFParser exists and supports .pdf. Parser hardening requires real golden tests.

8. Snapshot tests exist but are deferred for recording

The app test plan includes FinanceOSMacSnapshotTests. Snapshot baseline recording should be handled last, after core correctness and unit test phases are clean.

Phase 0 — Baseline audit and issue inventory
Objective

Create a complete current-state inventory before making behavioral changes.

Required work
Inspect the full repo structure, package graph, app targets, workflows, test targets, parser fixtures, scripts, and docs.
Run non-snapshot validations where available:
Swift package builds.
Swift package unit tests.
SwiftLint strict mode.
macOS app build.
Parser CLI build.
Identify all:
Compile errors.
Runtime-crash risks.
Lint violations.
Warnings.
Failing unit tests.
Broken package references.
Stale docs.
Stale test fixtures.
Unsafe suppressions.
Behavior mismatches.
Snapshot image recording is not run in this phase.
Snapshot test source code must still be checked for compile/API/lint issues.
Exit gate

Phase 0 is complete only when there is a written issue inventory grouped by severity and package area, and there are no unknown validation failures. Every discovered issue must either be assigned to a later phase or fixed immediately if it blocks baseline validation.

Phase 1 — Financial domain invariants
Objective

Define and enforce the core financial correctness rules before touching broader architecture.

Invariants to settle
Decide whether stored Transaction.amountMinorUnits is:
Always absolute with sign represented by transactionType, or
Signed with transactionType derived from sign.
Apply that invariant consistently across:
Parsers.
ParsedTransactionMapper.
Database model.
Repositories.
Analytics.
Transaction list UI.
Dashboard UI.
Tests.
Required fixes
Fix the analytics debit/credit mismatch.
Fix current-month totals.
Fix monthly summaries.
Fix recent activity amount display if affected.
Fix any parser sign bug discovered while testing, especially refunds/credits.
Add unit tests for:
Debit import.
Credit import.
Refund import.
Mixed debit/credit monthly summary.
Current month totals.
UI-facing amount formatting behavior where practical.
Exit gate

Phase 1 is complete only when all financial amount/sign behavior is consistent and fully guarded by unit tests. No known amount/sign bug may remain open.

Phase 2 — Import target matching and ledger integrity
Objective

Prevent transactions from being imported into the wrong ledger.

Required fixes
Make bank-aware matching the only canonical matching path.
Remove or rewrite AccountMatcher if it duplicates or weakens ImportTargetMatcher.
Require target matching to consider:
Bank identity.
Ledger kind.
Last four digits where available.
Ambiguity across multiple accounts/cards.
Remove silent defaulting to .bankAccount.
Convert stale/missing selected ledger into an explicit user-facing/domain error.
Add unit tests for:
Same last4 across different banks.
Same bank with multiple accounts.
Same bank with multiple cards.
Missing last4.
Unknown bank.
Stale/deleted selected ledger.
Explicit no-match behavior.
Exit gate

Phase 2 is complete only when no import can silently target the wrong ledger and all matching behavior is covered by tests.

Phase 3 — Deduplication and database consistency
Objective

Make deterministic deduplication correct, scoped, tested, and aligned with docs.

Required fixes
Decide the canonical dedup key.
Prefer ledger-scoped deduplication, such as (ledgerId, sourceFingerprint), unless there is a documented reason to keep global uniqueness.
Align:
SQLite schema.
GRDB model.
Migration tests.
Import repository logic.
Duplicate preview detection.
Parser fingerprint generation.
Architecture docs.
Remove inconsistent duplicate logic where possible.
Make duplicate handling explicit in ImportResult.
Add tests for:
Same transaction re-imported into same ledger.
Same fingerprint in different ledgers.
Duplicate rows inside same file.
Same date/amount/description but different source fingerprint.
Different statement sources.
Existing migrated databases.
Exit gate

Phase 3 is complete only when database deduplication, UI duplicate preview, and parser fingerprint behavior agree.

Phase 4 — Parser hardening and real-world ingestion behavior
Objective

Make the parser layer reliable against realistic statement inputs.

Required fixes
Align claimed support with actual support:
Either implement/wire the claimed formats and banks, or update docs/UI to mark them unsupported/experimental.
Fix file detection gaps.
Fix CSV parsing edge cases:
Quoted commas.
Escaped quotes.
CRLF.
BOM.
Empty rows.
Embedded newlines if supported.
Fix DateParser shared mutable formatter risk.
Set deterministic locale/calendar/time zone for date parsing.
Fix CLI options:
--source must force source selection, or be removed.
--password must work for password-protected supported formats, or be removed.
Add golden parser tests for each supported source:
HDFC bank.
HDFC card.
ICICI bank.
ICICI card.
Amex.
Add negative tests:
Unsupported extension.
Recognized extension but unknown institution.
Missing required columns.
Invalid date.
Invalid amount.
Empty file.
Malformed CSV/TXT.
Exit gate

Phase 4 is complete only when parser behavior is documented, realistic, tested, and does not silently skip malformed financial data without diagnostics.

Phase 5 — Repository, analytics, and scale correctness
Objective

Eliminate correctness and performance risks in repository-backed app behavior.

Required fixes
Move dashboard aggregation to repository/SQL-backed methods where appropriate.
Avoid fetching all transactions for simple aggregates.
Add paginated or filtered transaction fetch APIs if needed.
Ensure transaction filtering/search/date ranges produce correct financial-year behavior.
Review all GRDB queries for:
Missing indexes.
Wrong ordering.
Wrong archive behavior.
Missing foreign-key assumptions.
Add tests for:
Monthly aggregation.
Recent transactions limit.
Date range filtering.
Archived ledger behavior.
Delete restrictions.
Closing balance update ordering.
Exit gate

Phase 5 is complete only when repository and analytics behavior is correct, tested, and no known scale-related correctness issue remains.

Phase 6 — Build, lint, warnings, and CI enforcement
Objective

Make validation strict and trustworthy before snapshot work starts.

Required fixes
Ensure all packages build cleanly.
Ensure all non-snapshot unit tests pass.
Ensure SwiftLint strict mode passes.
Remove warning suppressions unless there is a documented and narrowly justified exception.
Remove unsafe warning suppression from test packages where possible.
Ensure CI does not skip critical package tests because a change is outside Packages/ when app code depends on package behavior.
Add app build validation if missing.
Do not add snapshot recording yet.
Exit gate

Phase 6 is complete only when code builds, unit tests pass, lint is clean, and CI accurately enforces the same standards.

Phase 7 — Documentation and source-of-truth alignment
Objective

Make README, architecture docs, parser docs, and workflow docs match the actual code.

Required fixes
Update architecture docs to reflect the real migration history and current schema.
Update parser support docs to distinguish:
Fully supported.
Experimental.
Planned.
Removed.
Update CLI docs to reflect actual supported options.
Update contribution docs to require:
Unit tests for bug fixes.
Parser fixtures for ingestion changes.
No snapshot recording until final snapshot phase.
Remove stale claims about unimplemented support.
Exit gate

Phase 7 is complete only when docs no longer describe nonexistent behavior or outdated schema decisions.

Phase 8 — Snapshot test cleanup and recording
Objective

Handle snapshot tests last, after all core code and unit tests are clean.

Required work
Fix any remaining snapshot test source-code issues:
Compile errors.
Stale APIs.
Bad mocks.
Broken fixtures.
Lint issues.
Run snapshot tests.
Review every snapshot diff manually.
Record/update snapshots only when the UI behavior is intentionally changed.
Do not use snapshot recording to hide layout bugs.
Ensure snapshot test changes are separated from unrelated logic changes where practical.
Exit gate

Phase 8 is complete only when snapshot tests pass and all snapshot diffs have been intentionally reviewed.

Final definition of done

The full task is done only when:

All known issues from the initial repo review are fixed.
All newly discovered issues during the phased work are fixed.
No compile errors remain.
No lint errors remain.
No non-snapshot unit tests fail.
No warnings are ignored.
Parser behavior is covered by realistic tests.
Financial amount/sign behavior is tested and consistent.
Deduplication behavior is tested and schema-backed.
Import target matching cannot silently choose the wrong ledger.
Docs match actual implementation.
Snapshot tests are addressed only in the final phase, with no premature snapshot recording.