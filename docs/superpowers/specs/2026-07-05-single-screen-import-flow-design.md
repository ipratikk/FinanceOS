# Single-Screen Import Flow — Design

## Context

The import flow is a 3-step wizard (`ImportViewModel.Step`: `.source` → `.upload` →
`.review`). The `.source` step lets the user manually pick a bank+product from a grid
before uploading anything. The `.review` step was built to show parsed transactions
and duplicate counts before committing an import.

Since the FinanceParsers retirement (client-side parsing removed, statement parsing
now owned entirely by `financeos-backend`), the client only gets `bankCode`/`last4`/
`transactionCount` from `previewStatement` — no line-item transaction data. As a
result, `.review` currently renders with zero transactions and zero duplicates every
time; it's dead weight showing an empty screen. `.source`'s manual bank picker is
also redundant now that `previewStatement` can auto-detect the bank from the file
itself.

Goal: collapse the flow to a single screen — drop a file, see what was detected,
confirm or pick the target ledger, import. This is a pure client-side (Swift) change;
no backend changes needed since `previewStatement`/`uploadStatement` already provide
everything required.

This is the first of three independent specs coming out of the same conversation
(UI flow → password-protected PDFs → Postgres column encryption). The other two are
out of scope here.

## Architecture

Replace `ImportViewModel.Step` (`.source`/`.upload`/`.review`) with an `ImportPhase`
enum owned by `ImportViewModel`, driving a single `ImportView` body with no stepper:

```swift
enum ImportPhase: Equatable {
    case idle
    case previewing                          // files dropped, awaiting previewStatement responses
    case readyToImport                        // previews in, target resolved or needs picking
    case importing                            // uploadStatement in flight
}
```

`.done` is not a persistent phase — on successful import, the existing
`lastImportResult` toast fires (unchanged mechanism) and the phase resets to `.idle`
immediately, matching current `resetToSource()` behavior (renamed `resetToIdle()`).

## Components

**`ImportView`** (rewritten): single `VStack`, content switches on `viewModel.phase`:
- `.idle` → the current drop-zone content from `uploadStep` (drag/drop + "Choose
  file" button + trust banners), copy corrected (see below)
- `.previewing` → drop zone replaced by a spinner + "Previewing statement..." (reuses
  existing `isLoading`/`currentFileIndex`/`totalFilesToParse` progress fields)
- `.readyToImport` → for each dropped file: detected bank/last4 (from
  `ParsedStatement.bankName`/`cardLast4`/`accountLast4`) + `TargetSelectionSection`
  (existing component, unchanged) for confirm-or-pick + an "Import" button, enabled
  once every file has a resolved target
- `.importing` → spinner, reusing existing `isLoading` styling

**Deleted** (dead once `.source`/`.review` are gone):
- `ImportSourceGrid.swift`, `ImportSourceCard.swift`, `SupportedSourcesView`,
  `sourceStep` (in `ImportView+Steps.swift`)
- `ImportStepper.swift` (no more multi-step to show)
- `ImportTransactionListView.swift`, `ImportTransactionSection.swift`,
  `ImportPreviewCard.swift`, `ImportPreviewView.swift`, `ImportPreviewView+Sections.swift`
  — all rendered transaction-list data that has been empty since the backend-parsing
  migration; removing rendering code for data that structurally can't exist, not a
  new capability loss
- `StatementSource`/`StatementSourceType`/`StatementSourceRegistry` usages in the
  Import views (the types stay in `FinanceCore` — `ImportTargetMatcher` and the
  Cards/Accounts "import to this ledger" entry point still use `StatementSource` for
  display, per below)

**`TargetSelectionSection`** (from `ImportView+Sections.swift`): unchanged, moves
from being review-step-only content to living inline in `.readyToImport`.

**`ImportFileParser`**, **`ImportTargetMatcher`**, **`ImportDuplicateDetector`**:
unchanged — they already operate correctly on the current preview data; only the
view layer consuming them changes shape.

## Entry-point fix: `pendingImportTarget`

Currently, clicking "Import statement" from a Card/Account's own screen sets both
`navigator.pendingImportTarget = .ledger(id)` and `navigator.pendingImportSource`
(`CardsView.swift`/`AccountsView.swift`), but `ImportView.onAppear` only ever reads
`pendingImportSource` (to pre-select the old source step) and discards
`pendingImportTarget` unread. This is a latent bug — the actual target the user
clicked never took effect.

Fix: `ImportView.onAppear` reads `pendingImportTarget` and pre-sets
`viewModel.importSession.selectedTarget` directly, skipping auto-match entirely
(the target is already known — no need to guess from `previewStatement`).
`pendingImportSource` is no longer read (no source step to pre-fill) but the
`CardsViewModel`/`AccountsViewModel` `statementSource(for:)` methods and
`AppNavigator.pendingImportSource` field are left in place since they're
harmless unread state, not worth a churny removal in this pass.

## Data Flow

1. User drops/selects file(s) on `.idle` → `viewModel.parseFiles(urls)` (unchanged)
2. Phase → `.previewing`; existing `parseFiles()` body calls `ImportFileParser.parse`
   per file (→ `previewStatement` GraphQL call), populates `parsedStatements`
3. `loadTargetsOnAppear()` + `autoSelectMatchingTarget()` run (unchanged) — if
   `pendingImportTarget` was set, this step is skipped since target is already
   resolved
4. Phase → `.readyToImport`; view renders detected info + target picker
5. User confirms/picks target(s), taps "Import" → `viewModel.importTransactions()`
   (unchanged — calls `uploadStatement` per file)
6. Phase → `.importing` → on completion, existing toast fires, phase resets to `.idle`

## Trust Banner Fix

`uploadTrustBanner(icon: "lock.shield.fill", title: "Local Processing", body: "Files
are parsed on-device. Your financial data never leaves your computer.")` is
factually wrong post-migration. Replace with copy describing the actual flow, e.g.
"Statements are sent to your FinanceOS backend for parsing — nothing is stored until
you confirm the import." The "Password Protected?" banner stays as-is (forward
reference to the password-protected-PDF spec, not yet implemented).

## Error Handling

Unchanged mechanism: `viewModel.errorMessage` displays inline (currently rendered
in both `uploadStep` and `ImportPreviewView`; consolidates to one error banner in
the single-screen view, shown regardless of phase).

## Testing

- Delete snapshot tests for removed views: `ImportFileListViewSnapshotTests.swift`,
  `ImportPreviewCardSnapshotTests.swift`, `ImportTransactionListViewSnapshotTests.swift`
- Add snapshot tests for the new single-screen view across phases: `.idle`,
  `.readyToImport` (auto-matched), `.readyToImport` (needs manual pick), `.importing`
- `ImportTargetMatcher`/`ImportTargetMatcherTests` (FinanceCore): unchanged, no
  changes needed
- Manual verification: launch app, drag a real statement file onto the import
  screen, confirm auto-match + import completes; verify entry from a Card's
  "Import statement" button pre-fills that card as the target
