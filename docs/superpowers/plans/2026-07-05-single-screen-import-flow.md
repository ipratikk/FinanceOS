# Single-Screen Import Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 3-step import wizard (source pick → upload → review) with a single screen that auto-detects the bank from the dropped file and lets the user confirm/pick the target ledger inline, then imports.

**Architecture:** `ImportViewModel.Step` (`.source`/`.upload`/`.review`) is replaced by `ImportViewModel.ImportPhase` (`.idle`/`.previewing`/`.readyToImport`/`.importing`). `ImportView`'s body switches on phase instead of rendering a 3-screen stepper. All backend calls (`previewStatement` via `ImportFileParser`, `uploadStatement` via `uploadFiles`) and matching logic (`ImportTargetMatcher`) are unchanged — only the view layer and the phase state machine change.

**Tech Stack:** Swift 6.1, SwiftUI, `@Observable`, XCTest + `SnapshotTesting` (existing `SnapshotTestable` base class).

## Global Constraints

- Line length: max 120 characters (CODING_STANDARDS.md)
- Function body: max 50 lines
- File length: max 400 lines
- All files must pass `swiftlint lint --strict --quiet` with zero output
- Multi-file drop stays supported; all dropped files share one target ledger (existing behavior, unchanged)
- `pendingImportTarget` (set when entering from a Card/Account's own screen) must pre-fill the target directly and skip auto-match — this was previously a latent bug (set by callers, never read)

---

### Task 1: Rewrite the ViewModel layer (Step → ImportPhase, drop dead plumbing)

**Files:**
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift` (full rewrite)
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSession.swift` (full rewrite)
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModelStateManagement.swift` (full rewrite)
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportDuplicateDetector.swift`

**Interfaces:**
- Produces: `ImportViewModel.ImportPhase` enum (`.idle`, `.previewing`, `.readyToImport`, `.importing`), `ImportViewModel.phase: ImportPhase`, `ImportViewModel.resetToIdle()`, `ImportViewModel.fileStatementPairs: [(url: URL, statement: ParsedStatement)]` (unchanged signature, kept), `ImportViewModel.selectedTarget: TransactionImportTarget?` (unchanged), `ImportViewModel.errorMessage: String?` (unchanged)
- Removed (do not reference in later tasks): `ImportViewModel.Step`, `ImportViewModel.currentStep`, `ImportViewModel.selectedSource`, `ImportViewModel.setSource(_:)`, `ImportViewModel.supportedSources`, `ImportViewModel.duplicateDetector`, `ImportViewModel.duplicateTransactionIndices`, `ImportViewModel.alreadyInDBIndices`, `ImportViewModel.selectSourceAndAdvance(_:)`, `ImportViewModel.advanceToReview()`, `ImportViewModel.backToUpload()`, `ImportViewModel.resetToSource()`, `ImportSession.selectedSource`

**Why these removals:** `duplicateDetector`/`duplicateTransactionIndices`/`alreadyInDBIndices` operate on `statement.transactions`, which has been an empty array for every statement since the FinanceParsers retirement (parsing moved server-side; `previewStatement` only returns `bankCode`/`last4`/`transactionCount`, no line items). The dedup detector has been unreachable dead code producing empty results on every call — not a capability being removed, a computation that already always no-ops. `selectedSource`/`setSource`/`supportedSources`/`selectSourceAndAdvance` back the deleted source-selection step. `advanceToReview()` was already unused (verified via repo-wide grep — zero call sites). `backToUpload()`/`resetToSource()` are replaced by the single `resetToIdle()`, since there's no longer a separate "upload step" to go back to.

- [ ] **Step 1: Rewrite `ImportSession.swift`**

```swift
import FinanceCore
import Foundation
import Observation

/// Observable state bag that tracks a single end-to-end import flow: file selection → parse → match → confirm → result.
/// Owned by the import ViewModel; reset between imports so no stale state leaks across sessions.
@Observable
@MainActor
final class ImportSession {
    // MARK: - Parse phase

    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []

    /// Preview phase — maps each statement's UUID to the ledger the user confirmed it belongs to.
    var matchedLedgers: [UUID: Ledger] = [:]

    /// Target creation phase — holds transient form state while the user creates a new ledger mid-import.
    var targetBeingCreated: TargetCreationState?

    // MARK: - Final import

    var selectedTarget: TransactionImportTarget?
    var importResult: ImportResult?

    // MARK: - Error handling

    var errorMessage: String?
    var isLoading = false

    init() {}

    func reset() {
        fileURLs = []
        parsedStatements = []
        matchedLedgers = [:]
        targetBeingCreated = nil
        selectedTarget = nil
        importResult = nil
        errorMessage = nil
        isLoading = false
    }
}
```

- [ ] **Step 2: Rewrite `ImportViewModel.swift`**

```swift
@preconcurrency import Apollo
@preconcurrency import ApolloAPI
import FinanceCore
import FinanceOSAPI
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    enum ImportPhase: Equatable {
        case idle
        case previewing
        case readyToImport
        case importing
    }

    var phase: ImportPhase = .idle
    var isDraggedOver: Bool = false

    let importSession: ImportSession
    let graphQLClient: ApolloGraphQLClient
    let fileParser: any StatementParsingProtocol

    var ledgers: [Ledger] = []
    var banks: [Bank] = []
    var lastImportResult: ImportResult?
    var currentFileIndex: Int = 0
    var totalFilesToParse: Int = 0

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(importSession.fileURLs, importSession.parsedStatements).map { ($0, $1) }
    }

    var fileURLs: [URL] {
        get { importSession.fileURLs }
        set { importSession.fileURLs = newValue }
    }

    var parsedStatements: [ParsedStatement] {
        get { importSession.parsedStatements }
        set { importSession.parsedStatements = newValue }
    }

    var selectedTarget: TransactionImportTarget? {
        get { importSession.selectedTarget }
        set { importSession.selectedTarget = newValue }
    }

    var isLoading: Bool {
        get { importSession.isLoading }
        set { importSession.isLoading = newValue }
    }

    var errorMessage: String? {
        get { importSession.errorMessage }
        set { importSession.errorMessage = newValue }
    }

    var importResult: ImportResult? {
        get { importSession.importResult }
        set { importSession.importResult = newValue }
    }

    init(
        graphQLClient: ApolloGraphQLClient,
        initialTarget: TransactionImportTarget? = nil,
        fileParser: (any StatementParsingProtocol)? = nil
    ) {
        importSession = ImportSession()
        self.graphQLClient = graphQLClient
        self.fileParser = fileParser ?? ImportFileParser(graphQLClient: graphQLClient)
        if let initialTarget {
            importSession.selectedTarget = initialTarget
        }
    }

    func setFileURLs(_ urls: [URL]) {
        logger.info("setFileURLs called with \(urls.count, privacy: .public) file(s)")
        importSession.fileURLs = urls
        importSession.errorMessage = nil
        logger.debug("fileURLs updated, errorMessage cleared")
    }

    func parseFiles(_ urls: [URL]) {
        setFileURLs(urls)
        parseFiles()
    }

    func parseFiles() {
        logger.info("parseFiles() called, scheduling Task")
        Task {
            guard !importSession.fileURLs.isEmpty else {
                importSession.errorMessage = "No files selected"
                return
            }

            phase = .previewing
            importSession.isLoading = true
            importSession.errorMessage = nil
            totalFilesToParse = importSession.fileURLs.count
            currentFileIndex = 0
            var statements: [ParsedStatement] = []
            let parser = fileParser

            for fileURL in importSession.fileURLs {
                do {
                    let statement = try await parser.parse(fileURL: fileURL)
                    statements.append(statement)
                    currentFileIndex += 1
                } catch let error as FinanceCore.TransactionImportError {
                    importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    phase = .idle
                    return
                } catch {
                    let fileName = fileURL.lastPathComponent
                    let errorDesc = error.localizedDescription
                    importSession.errorMessage = "Error parsing \(fileName): \(errorDesc)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    phase = .idle
                    return
                }
            }

            importSession.parsedStatements = statements
            await loadTargetsOnAppear()
            await autoSelectMatchingTarget()
            phase = .readyToImport
            importSession.isLoading = false
            currentFileIndex = 0
            totalFilesToParse = 0
        }
    }

    func importTransactions() {
        Task {
            guard !importSession.fileURLs.isEmpty,
                  let target = importSession.selectedTarget,
                  case let .ledger(ledgerId) = target
            else {
                importSession.errorMessage = "Select a ledger before importing"
                return
            }
            phase = .importing
            importSession.isLoading = true
            importSession.errorMessage = nil
            importSession.importResult = nil
            do {
                let (inserted, skipped) = try await uploadFiles(ledgerId: ledgerId)
                let result = ImportResult(inserted: inserted, skipped: skipped)
                importSession.importResult = result
                lastImportResult = result
                resetToIdle()
                importSession.isLoading = false
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    lastImportResult = nil
                }
            } catch {
                let desc = error.localizedDescription
                logger.error("Import failed: \(desc, privacy: .public)")
                importSession.errorMessage = "Import failed: \(desc)"
                importSession.isLoading = false
                phase = .readyToImport
            }
        }
    }

    private func uploadFiles(ledgerId: UUID) async throws -> (inserted: Int, skipped: Int) {
        var totalInserted = 0
        var totalSkipped = 0
        for fileURL in importSession.fileURLs {
            let fileData = try Data(contentsOf: fileURL)
            let file = GraphQLFile(
                fieldName: "file",
                originalName: fileURL.lastPathComponent,
                mimeType: "text/csv",
                data: fileData
            )
            let mutation = UploadStatementMutation(ledgerId: ledgerId.uuidString, file: "")
            let response = try await graphQLClient.upload(mutation: mutation, files: [file])
            let result = response.uploadStatement
            totalInserted += result.imported
            totalSkipped += result.duplicates
            logger.logInfo("File uploaded: {imported} imported, {dups} duplicates", [
                "imported": result.imported,
                "dups": result.duplicates
            ])
        }
        return (totalInserted, totalSkipped)
    }
}
```

Note the added `phase = .readyToImport` in `importTransactions()`'s catch branch (line near the end): on upload failure, the phase returns to `.readyToImport` so the user sees the error and can retry, instead of getting stuck showing the `.importing` spinner forever. The old code didn't need this because `.review` was already the terminal step on failure; the new phase model needs an explicit revert.

- [ ] **Step 2: Rewrite `ImportViewModelStateManagement.swift`**

```swift
import FinanceCore
import FinanceOSAPI
import Foundation
import OSLog

extension ImportViewModel {
    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading ledgers and banks via GraphQL")
            let ledgerData = try await graphQLClient.fetch(query: GetLedgersQuery())
            let bankData = try await graphQLClient.fetch(query: GetBanksQuery())
            ledgers = ledgerData.ledgers.map(GraphQLMappings.mapLedger)
            banks = bankData.banks.map(GraphQLMappings.mapBank)
            logger.logDebug("Loaded {ledgers} ledgers and {banks} banks", [
                "ledgers": ledgers.count,
                "banks": banks.count
            ])
        } catch {
            let errorMsg = error.localizedDescription
            logger.error("Failed to load targets: \(errorMsg, privacy: .public)")
            importSession.errorMessage = errorMsg
        }
    }

    func autoSelectMatchingTarget() async {
        guard let statement = importSession.parsedStatements.first else { return }
        if let target = FinanceCore.ImportTargetMatcher.bestTarget(
            for: statement,
            ledgers: ledgers,
            banks: banks
        ) {
            importSession.selectedTarget = target
        }
    }

    func reset() {
        importSession.reset()
        ledgers = []
        banks = []
    }

    // MARK: - Phase Navigation

    func resetToIdle() {
        reset()
        phase = .idle
    }
}
```

- [ ] **Step 3: Delete `ImportDuplicateDetector.swift`**

```bash
git rm Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportDuplicateDetector.swift
```

- [ ] **Step 4: Build FinanceCore-dependent target to confirm no stale references yet**

This won't fully compile yet (view layer still references deleted members) — that's expected. Just confirm the ViewModel layer itself has no self-inconsistency:

Run: `swiftc -parse Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSession.swift Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModelStateManagement.swift 2>&1 | grep -v "cannot find\|no such module" | head -20`

Expected: only "cannot find type/module" errors (unresolved cross-file/module references, fine at this stage), no syntax errors specific to these 3 files' own logic (e.g. no "expected expression", no mismatched braces).

- [ ] **Step 5: Commit**

```bash
git add Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModel.swift \
        Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSession.swift \
        Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewModelStateManagement.swift \
        Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/Services/ImportDuplicateDetector.swift
git commit -m "refactor(import): replace Step enum with ImportPhase, drop dead dedup/source plumbing"
```

(This commit alone won't compile the full app target — that's expected and fine; Task 3 finishes the wiring. Do not run the full build gate until Task 3.)

---

### Task 2: Extract `ImportTargetSection` (salvage the working target-picker logic)

The only *working* ledger-picker UI today is `targetSelectionMenu` and its supporting
methods in `ImportPreviewView+Sections.swift` (an extension on `ImportPreviewView`,
which is being deleted). A separate, unused `TargetSelectionSection` struct exists in
`ImportView+Sections.swift` with broken "New Account"/"New Card" buttons (empty
`action: {}` closures, never wired) — that one is dead and gets deleted in Task 3, not
salvaged.

**Files:**
- Create: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportTargetSection.swift`

**Interfaces:**
- Consumes: `ImportViewModel.selectedTarget`, `ImportViewModel.ledgers`, `ImportViewModel.importSession.parsedStatements`, `ImportViewModel.importSession.targetBeingCreated`, `ImportViewModel.createTargetFromDetected(...)` (all unchanged, from Task 1's `ImportViewModel`), `TargetCreationState` (unchanged, `Presentation/Import/TargetCreationState.swift`), `CardEditView` (unchanged), `ImportHelpers.fuzzyMatch` (unchanged), `Banks` (unchanged, `FinanceCore`)
- Produces: `struct ImportTargetSection: View`, initialized as `ImportTargetSection(viewModel: viewModel)` — a self-contained "pick or create target ledger" button + popover + create-ledger sheet, for later tasks to embed inline in the ready-to-import screen

- [ ] **Step 1: Create `ImportTargetSection.swift`**

```swift
import FinanceCore
import FinanceUI
import SwiftUI

/// Self-contained "pick or create target ledger" control: a button that opens a
/// popover listing accounts/cards, with "New Account.../New Card..." actions that
/// open the create-ledger sheet. Used inline on the ready-to-import screen.
struct ImportTargetSection: View {
    let viewModel: ImportViewModel

    @State private var sheetCreationItem: TargetCreationState?
    @State private var isTargetMenuOpen = false

    var body: some View {
        targetSelectionMenu
            .sheet(item: $sheetCreationItem) { item in
                if item.isCard {
                    CardEditView(mode: .createCard(prefill: item, onCommit: handleCreationCommit))
                } else {
                    CardEditView(mode: .createAccount(prefill: item, onCommit: handleCreationCommit))
                }
            }
            .onChange(of: viewModel.importSession.targetBeingCreated) { _, newValue in
                sheetCreationItem = newValue
            }
    }

    private var targetSelectionMenu: some View {
        let selected: (name: String, icon: String)? = {
            guard let target = viewModel.selectedTarget,
                  case let .ledger(id) = target,
                  let ledger = viewModel.ledgers.first(where: { $0.id == id })
            else { return nil }
            let icon = ledger.kind == .creditCard ? "creditcard" : "building.columns"
            return (ledger.displayName, icon)
        }()

        return FDSLiquidButton(
            selected?.name ?? "Select destination...",
            leadingIcon: selected?.icon,
            trailingIcon: "chevron.up.chevron.down",
            variant: .primary,
            action: { isTargetMenuOpen.toggle() }
        )
        .popover(isPresented: $isTargetMenuOpen, arrowEdge: .top) {
            targetMenuPopover
        }
    }

    private var targetMenuPopover: some View {
        FDSGlassSurface(elevation: .floating, cornerRadius: AppRadius.lg, padding: 0) {
            VStack(spacing: 0) {
                accountMenuRows
                Divider()
                    .padding(AppSpacing.sm)
                cardMenuRows
                if viewModel.selectedTarget != nil {
                    Divider().padding(.horizontal, AppSpacing.sm)
                    clearMenuRow
                }
            }
            .frame(minWidth: 260)
            .padding(.vertical, AppSpacing.compact)
        }
    }

    private var accountMenuRows: some View {
        let accounts = viewModel.ledgers.filter { $0.kind == .bankAccount }
        return VStack(spacing: 0) {
            ForEach(accounts) { account in
                let isSelected: Bool = {
                    if case let .ledger(id) = viewModel.selectedTarget { return id == account.id }
                    return false
                }()
                ledgerMenuRow(title: account.displayName, icon: "building.columns", isSelected: isSelected) {
                    viewModel.selectedTarget = .ledger(account.id)
                    isTargetMenuOpen = false
                }
            }
            menuActionRow(title: "New Account...", icon: "plus.circle") {
                isTargetMenuOpen = false
                initializeCreateSheet(isCard: false)
            }
        }
    }

    private var cardMenuRows: some View {
        let cards = viewModel.ledgers.filter { $0.kind == .creditCard }
        return VStack(spacing: 0) {
            ForEach(cards) { card in
                let isSelected: Bool = {
                    if case let .ledger(id) = viewModel.selectedTarget { return id == card.id }
                    return false
                }()
                ledgerMenuRow(title: card.displayName, icon: "creditcard", isSelected: isSelected) {
                    viewModel.selectedTarget = .ledger(card.id)
                    isTargetMenuOpen = false
                }
            }
            menuActionRow(title: "New Card...", icon: "plus.circle") {
                isTargetMenuOpen = false
                initializeCreateSheet(isCard: true)
            }
        }
    }

    private var clearMenuRow: some View {
        Button(action: { viewModel.selectedTarget = nil; isTargetMenuOpen = false }, label: {
            HStack {
                Spacer()
                FDSLabel("Clear Selection")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.Text.tertiary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    private func ledgerMenuRow(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action, label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(AppTypography.captionLg)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.tertiary)
                    .frame(width: 16)
                FDSLabel(title)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .background(isSelected ? AppColors.accent.opacity(0.08) : AppColors.clear)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    private func menuActionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 16)
                FDSLabel(title)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(AppColors.accent)
                Spacer()
            }
            .padding(.vertical, AppSpacing.compact)
            .padding(.horizontal, AppSpacing.md)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    private func initializeCreateSheet(isCard: Bool) {
        guard let statement = viewModel.importSession.parsedStatements.first else {
            var state = TargetCreationState()
            state.isCard = isCard
            viewModel.importSession.targetBeingCreated = state
            return
        }

        var state = TargetCreationState()
        state.isCard = isCard
        state.initializeFromStatement(statement)

        let detected = statement.bankName.isEmpty ? "Unknown" : statement.bankName
        let matchingBankCase = Banks.allCases.first { bankCase in
            ImportHelpers.fuzzyMatch(bankCase.displayName, detected)
        }
        state.selectedBank = matchingBankCase

        viewModel.importSession.targetBeingCreated = state
    }

    private func handleCreationCommit(_ state: TargetCreationState) {
        sheetCreationItem = nil
        viewModel.importSession.targetBeingCreated = nil
        Task {
            await viewModel.createTargetFromDetected(
                customName: state.customName,
                nickname: state.nickname,
                last4: state.last4,
                selectedBank: state.selectedBank,
                ownerName: state.cardholderName,
                accountType: state.accountType,
                cardType: state.cardType,
                cardProductId: state.cardProductId,
                encryptedCardNumber: state.encryptedCardNumber,
                linkedLedgerId: state.linkedLedgerId,
                isCard: state.isCard
            )
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportTargetSection.swift
git commit -m "feat(import): extract ImportTargetSection from ImportPreviewView+Sections"
```

---

### Task 3: Rewrite `ImportView` as a single phase-driven screen; delete obsolete files

**Files:**
- Modify: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView.swift` (full rewrite)
- Create: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView+Phases.swift` (replaces `ImportView+Steps.swift`)
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView+Steps.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView+Sections.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewHelpers.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportStepper.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSourceGrid.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSourceCard.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportFileListView.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportPreviewView.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportPreviewView+Sections.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportPreviewCard.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportTransactionListView.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportTransactionSection.swift`

**Deletion rationale (verified via repo-wide grep, zero other call sites for each):**
- `ImportView+Sections.swift`: `SupportedSourcesView` (backs deleted source step) and
  `TargetSelectionSection` (dead — never instantiated anywhere, its "New
  Account"/"New Card" buttons are empty closures) are both unused/obsolete.
- `ImportViewHelpers.swift`: `SourcePickerSection`, `DropZoneView`,
  `FileSelectionPlaceholder` — all three already unused anywhere in the app
  (pre-existing dead code, not caused by this change).
- `ImportFileListView.swift`: already unused in the real app (only referenced by its
  own now-deleted snapshot test).
- `ImportPreviewCard.swift`: already unused in the real app (only referenced by its
  own now-deleted snapshot test).
- `ImportPreviewView.swift` / `+Sections.swift` / `ImportTransactionListView.swift` /
  `ImportTransactionSection.swift`: render transaction-list/dedup data that has been
  empty for every import since the FinanceParsers retirement; the actual working
  target-picker logic from `+Sections.swift` was extracted to `ImportTargetSection`
  in Task 2 before this deletion.

**Interfaces:**
- Consumes: `ImportViewModel.phase`, `.isDraggedOver`, `.isLoading`, `.errorMessage`, `.currentFileIndex`, `.totalFilesToParse`, `.fileURLs`, `.fileStatementPairs`, `.selectedTarget`, `.parseFiles(_:)`, `.importTransactions()`, `.resetToIdle()`, `.lastImportResult` (all from Task 1), `ImportTargetSection` (from Task 2), `AppNavigator.pendingImportTarget`, `.pendingImportSource`, `.toastPresenter` (unchanged, `Presentation/Navigation/AppNavigator.swift`)
- Produces: `ImportView.idleContent`, `.previewingContent`, `.readyToImportContent`, `.importingContent` (computed properties consumed by `ImportView.body`)

- [ ] **Step 1: Delete the eleven obsolete files**

```bash
git rm Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView+Steps.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportView+Sections.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportViewHelpers.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportStepper.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSourceGrid.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportSourceCard.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportFileListView.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportPreviewView.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportPreviewView+Sections.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportPreviewCard.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportTransactionListView.swift \
       Apps/FinanceOSMac/FinanceOSMac/Presentation/Import/ImportTransactionSection.swift
```

- [ ] **Step 2: Create `ImportView+Phases.swift`**

```swift
import AppKit
import FinanceCore
import FinanceUI
import SwiftUI
import UniformTypeIdentifiers

extension ImportView {
    // MARK: - Idle: drop zone

    var idleContent: some View {
        VStack {
            ZStack {
                VStack(spacing: AppSpacing.xl) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.accent)

                    VStack(spacing: AppSpacing.md) {
                        FDSLabel(viewModel.isDraggedOver ? "Release to upload" : "Drag and drop statement")
                            .font(AppTypography.headingXL)
                            .foregroundColor(AppColors.Text.primary)

                        if !viewModel.isDraggedOver {
                            FDSLabel("Upload your bank statement in PDF, CSV, or XLSX format. Max file size is 10MB.")
                                .font(AppTypography.bodyLg)
                                .foregroundColor(AppColors.Text.tertiary)
                        }

                        FDSLiquidButton("Choose file", leadingIcon: "doc", variant: .primary, action: openFilePicker)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(AppColors.clear)
                    .onDrop(of: [.fileURL], isTargeted: $viewModel.isDraggedOver) { providers in
                        var fileURLs: [URL] = []
                        let group = DispatchGroup()

                        for provider in providers {
                            group.enter()
                            provider.loadObject(ofClass: NSURL.self) { nsurl, _ in
                                if let url = nsurl as? URL {
                                    fileURLs.append(url)
                                }
                                group.leave()
                            }
                        }

                        group.notify(queue: .main) {
                            if !fileURLs.isEmpty {
                                Task { @MainActor in
                                    viewModel.parseFiles(fileURLs)
                                }
                            }
                        }
                        return true
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            .background(viewModel.isDraggedOver ? AppColors.accent.opacity(0.05) : AppColors.base)

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            Divider()
            uploadTrustBanners
        }
    }

    // MARK: - Previewing: spinner while previewStatement runs

    var previewingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)

            if viewModel.totalFilesToParse > 1 {
                FDSLabel("Previewing file \(viewModel.currentFileIndex + 1) of \(viewModel.totalFilesToParse)...")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.tertiary)
            } else {
                FDSLabel("Previewing statement...")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ready to import: detected info + target + Import button

    var readyToImportContent: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            FDSCard(padded: false) {
                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        FDSLabel("Ready to import")
                            .font(AppTypography.headingMd)
                            .foregroundColor(AppColors.accent)

                        FDSLabel(detectedSummary)
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.Text.tertiary)
                    }
                    Spacer()
                    ImportTargetSection(viewModel: viewModel)
                }
                .padding(AppSpacing.lg)
            }

            ScrollView {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.fileStatementPairs, id: \.url) { pair in
                        detectedFileRow(pair)
                    }
                }
                .padding(AppSpacing.lg)
            }

            Spacer()

            FDSCard(padded: false) {
                HStack(spacing: AppSpacing.md) {
                    FDSLiquidButton("Cancel", variant: .ghost, action: viewModel.resetToIdle)
                    Spacer()
                    FDSLiquidButton(
                        "Import",
                        variant: .primary,
                        isEnabled: viewModel.selectedTarget != nil,
                        action: viewModel.importTransactions
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    // MARK: - Importing: spinner

    var importingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            FDSLabel("Importing...")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.Text.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Shared helpers

    private var detectedSummary: String {
        let fileCount = viewModel.parsedStatements.count
        return fileCount == 1
            ? (viewModel.fileURLs.first?.lastPathComponent ?? "1 file")
            : "\(fileCount) files"
    }

    private func detectedFileRow(_ pair: (url: URL, statement: ParsedStatement)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(pair.url.lastPathComponent)
                    .font(AppTypography.bodyLg)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)

                FDSLabel(pair.statement.bankName)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.primary)
            }

            Spacer()

            if let last4 = pair.statement.cardLast4 ?? pair.statement.accountLast4 {
                FDSLabel("•••• \(last4)")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface2)
        .cornerRadius(AppRadius.md)
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.danger)
            FDSLabel(error)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.Text.primary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.danger.opacity(0.1))
        .cornerRadius(AppRadius.sm)
        .padding(AppSpacing.lg)
    }

    private var uploadTrustBanners: some View {
        HStack(spacing: AppSpacing.md) {
            uploadTrustBanner(
                icon: "lock.shield.fill",
                title: "Secure Upload",
                body: "Statements are sent to your FinanceOS backend for parsing — "
                    + "nothing is stored until you confirm the import."
            )
            uploadTrustBanner(
                icon: "key.fill",
                title: "Password Protected?",
                body: "You'll be prompted if your file requires a password to open."
            )
        }
        .padding(AppSpacing.lg)
    }

    private func uploadTrustBanner(icon: String, title: String, body: String) -> some View {
        FDSCard {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                FDSImage(fallbackSymbol: icon)
                    .font(AppTypography.bodyLg)
                    .foregroundColor(AppColors.accent)

                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    FDSLabel(title)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel(body)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.Text.secondary)
                }

                Spacer()
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            FinanceCore.StatementFileFormat.csv.utType,
            FinanceCore.StatementFileFormat.txt.utType,
            FinanceCore.StatementFileFormat.xlsx.utType,
            FinanceCore.StatementFileFormat.pdf.utType
        ]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK, !panel.urls.isEmpty {
            viewModel.parseFiles(panel.urls)
        }
    }
}
```

Note: the trust banner copy is corrected here — the old text ("Files are parsed
on-device. Your financial data never leaves your computer.") has been false since
the backend-parsing migration; the new copy ("Statements are sent to your FinanceOS
backend for parsing...") describes the actual flow.

- [ ] **Step 3: Rewrite `ImportView.swift`**

```swift
import FinanceCore
import FinanceUI
import SwiftUI

struct ImportView: View {
    @State var viewModel: ImportViewModel

    init(viewModel: ImportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                FDSLabel("Import Statement")
                    .font(AppTypography.headingXL)
                    .foregroundColor(AppColors.Text.primary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Group {
                switch viewModel.phase {
                case .idle:
                    idleContent
                case .previewing:
                    previewingContent
                case .readyToImport:
                    readyToImportContent
                case .importing:
                    importingContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(AppSpacing.x6l)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
        .onChange(of: viewModel.lastImportResult) { _, newValue in
            if let result = newValue {
                navigator.toastPresenter.show(
                    message: "Imported \(result.inserted) transaction\(result.inserted == 1 ? "" : "s")" +
                        (result.skipped > 0 ? " · \(result.skipped) skipped" : ""),
                    type: .success,
                    position: .top,
                    horizontalAlignment: .trailing,
                    duration: 4.0
                )
            }
        }
        .onAppear {
            if let target = navigator.pendingImportTarget {
                viewModel.selectedTarget = target
                navigator.pendingImportTarget = nil
            }
            navigator.pendingImportSource = nil
            Task {
                await viewModel.loadTargetsOnAppear()
            }
        }
    }
}

#Preview {
    ImportView(
        viewModel: ImportViewModel(
            graphQLClient: ApolloGraphQLClient()
        )
    )
}
```

This fixes the latent bug described in Global Constraints: `pendingImportTarget` is
now read and applied (`viewModel.selectedTarget = target`); previously it was set by
`CardsView.swift`/`AccountsView.swift` and silently discarded here.

- [ ] **Step 4: Build the macOS app target**

Run: `Scripts/build-macos.sh`
Expected: `✓ macOS build complete` with no `error:` lines. If there are errors, they
will be either (a) leftover references to a deleted symbol — grep the error's file
for the deleted name and remove/update it, or (b) a typo introduced when copying the
code above — compare character-for-character against this step's code block.

- [ ] **Step 5: Run SwiftLint**

Run: `swiftlint lint --strict --quiet`
Expected: no output. If there's output, fix the reported violations (likely line
length or trailing whitespace from copy-paste) and re-run until clean.

- [ ] **Step 6: Commit**

```bash
git add -A
git status -s
```

Confirm the status shows exactly: 12 deletions (11 from Step 1 of this task, plus
`ImportDuplicateDetector.swift` already committed in Task 1), 1 new file
(`ImportView+Phases.swift`), and modifications to `ImportView.swift`. No unexpected
files.

```bash
git commit -m "refactor(import): collapse 3-step wizard into single phase-driven screen"
```

---

### Task 4: Update snapshot tests

**Files:**
- Delete: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportFileListViewSnapshotTests.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPreviewCardSnapshotTests.swift`
- Delete: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportTransactionListViewSnapshotTests.swift`
- Create: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportTargetSectionSnapshotTests.swift`
- No change needed: `Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportFlowSnapshotTests.swift` (constructs a default `ImportViewModel` and snapshots `ImportView` — this now captures the new `.idle` drop-zone screen instead of the old source-grid screen; the test code itself doesn't reference any deleted symbol, so it needs no edits, just re-recording — see Step 4)

**Interfaces:**
- Consumes: `ImportTargetSection` (from Task 2), `SnapshotTestable.verifyComponentSnapshots(_:size:)` (unchanged, `Helpers/SnapshotTestable.swift`), `PreviewAccounts.checking()`/`.creditCard()` (unchanged, `FinanceTesting`), `PreviewBanks.hdfc()` (unchanged, `FinanceTesting`)

- [ ] **Step 1: Delete the three obsolete snapshot test files**

```bash
git rm Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportFileListViewSnapshotTests.swift \
       Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportPreviewCardSnapshotTests.swift \
       Apps/FinanceOSMac/FinanceOSMacSnapshotTests/Flows/ImportTransactionListViewSnapshotTests.swift
```

- [ ] **Step 2: Create `ImportTargetSectionSnapshotTests.swift`**

```swift
import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportTargetSectionSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_import_target_section_no_selection() {
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        viewModel.ledgers = [PreviewAccounts.checking(), PreviewAccounts.creditCard()]
        viewModel.banks = [PreviewBanks.hdfc()]
        let view = ImportTargetSection(viewModel: viewModel)
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 60))
    }

    func test_import_target_section_selected() {
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        let checking = PreviewAccounts.checking()
        viewModel.ledgers = [checking, PreviewAccounts.creditCard()]
        viewModel.banks = [PreviewBanks.hdfc()]
        viewModel.selectedTarget = .ledger(checking.id)
        let view = ImportTargetSection(viewModel: viewModel)
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 60))
    }
}
```

- [ ] **Step 3: Run the new snapshot tests to record baseline images**

Run: `xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -destination 'platform=macOS,arch=arm64' -only-testing:FinanceOSMacSnapshotTests/ImportTargetSectionSnapshotTests 2>&1 | tail -30`

These will FAIL on first run (no reference image exists yet). Temporarily set
`override var record: Bool { true }` in `ImportTargetSectionSnapshotTests`, re-run the
same command to generate reference images under `__Snapshots__/`, then set `record`
back to `false` and re-run once more to confirm the test now passes against the
recorded image.

Expected after the final run: `** TEST SUCCEEDED **`

- [ ] **Step 4: Re-record `ImportFlowSnapshotTests`**

The existing reference image for `test_import_view` shows the old source-grid
screen; it must be re-recorded to show the new idle drop-zone screen. Temporarily
set `override var record: Bool { true }` in `ImportFlowSnapshotTests.swift`, run:

`xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -destination 'platform=macOS,arch=arm64' -only-testing:FinanceOSMacSnapshotTests/ImportFlowSnapshotTests 2>&1 | tail -20`

then set `record` back to `false` and re-run to confirm it passes.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "test(import): replace dead-view snapshot tests with ImportTargetSection coverage"
```

---

### Task 5: Full verification and manual smoke test

**Files:** none (verification only)

- [ ] **Step 1: Full SwiftLint pass**

Run: `swiftlint lint --strict --quiet`
Expected: no output.

- [ ] **Step 2: Full FinanceCore test suite**

Run: `swift test --package-path Packages/FinanceCore --parallel 2>&1 | tail -10`
Expected: all tests pass (44 tests as of the last verified run — `ImportTargetMatcher`
is unchanged by this plan, so this count should not change).

- [ ] **Step 3: Full macOS build**

Run: `Scripts/build-macos.sh`
Expected: `✓ macOS build complete`, no errors.

- [ ] **Step 4: Repo-wide grep for stale references**

Run: `grep -rln "ImportViewModel\.Step\|currentStep\|selectedSource\|duplicateDetector\|ImportStepper\|ImportSourceGrid\|ImportPreviewView\|ImportTransactionListView\|ImportTransactionSection\|ImportPreviewCard\|ImportFileListView\b" Apps/FinanceOSMac/ 2>/dev/null`
Expected: no output (empty). If anything matches, it's a missed reference — fix it
and re-run this grep and Step 3's build until both are clean.

- [ ] **Step 5: Manual verification — launch the app**

Requires a running local `financeos-backend` (Docker Compose, per
`README.md`'s "GraphQL Backend & Codegen" section).

Launch the built app:
```bash
open ~/Library/Developer/Xcode/DerivedData/FinanceOS*/Build/Products/Debug/FinanceOSMac.app
```

Manually verify:
1. Navigate to Import — confirm the screen shows the drop zone directly (no
   bank-picker grid screen first)
2. Drop or select a real statement file — confirm it transitions to a brief
   "Previewing statement..." spinner, then to the ready-to-import screen showing
   the detected bank name and (if applicable) last4
3. Confirm the target ledger is either auto-selected (if there's an unambiguous
   match) or the "Select destination..." button opens a working picker
4. Tap Import — confirm it transitions to "Importing...", then shows the success
   toast and resets to the drop zone
5. From a Card's own detail screen, tap "Import statement" — confirm the import
   screen opens with that card pre-selected as the target (verifies the
   `pendingImportTarget` fix), skipping straight to file drop with the target
   already set once a file is dropped

Report any visual glitches or crashes found — do not silently work around them,
flag for follow-up.

- [ ] **Step 6: Final commit check**

```bash
git log --oneline -6
git status -s
```

Expected: 4 commits from Tasks 1-4 (ViewModel rewrite, ImportTargetSection extraction,
View rewrite + deletions, snapshot test updates), clean working tree.
