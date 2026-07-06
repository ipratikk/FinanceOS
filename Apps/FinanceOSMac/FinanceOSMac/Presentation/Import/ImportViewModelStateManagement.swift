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
        guard importSession.selectedTarget == nil else { return }
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

    // MARK: - Password retry

    /// Tries `previewStatement` for one file, resolving a password via Keychain or
    /// the password-prompt sheet if the backend reports `passwordRequired`. Loops
    /// until the file parses, the user cancels (throws `.passwordProtected` to
    /// abort this file), or a non-password error occurs.
    func parseWithPasswordRetry(fileURL: URL, parser: any StatementParsingProtocol) async throws -> ParsedStatement {
        var isRetry = false
        var password: String? = knownPassword(for: fileURL)

        while true {
            do {
                let statement = try await parser.parse(fileURL: fileURL, password: password)
                if let password {
                    importSession.filePasswords[fileURL] = password
                }
                return statement
            } catch FinanceCore.TransactionImportError.passwordProtected {
                guard let entered = await requestPassword(for: fileURL, isRetry: isRetry) else {
                    throw FinanceCore.TransactionImportError.passwordProtected(fileURL.lastPathComponent)
                }
                password = entered
                isRetry = true
            }
        }
    }

    private func knownPassword(for fileURL: URL) -> String? {
        guard case let .ledger(ledgerId) = importSession.selectedTarget else { return nil }
        return passwordStore.password(for: ledgerId)
    }

    /// Presents the password sheet and suspends until the user submits or cancels.
    /// Returns nil on cancel. **Does not save to Keychain directly** — at prompt
    /// time (during `previewStatement`, inside `parseFiles()`'s per-file loop) the
    /// target ledger is usually still unresolved (auto-match/manual-pick both
    /// happen after preview succeeds — see the design spec's Data Flow step 3).
    /// If the user checked "Save to Keychain", the intent is recorded in
    /// `importSession.pendingKeychainSaves` and actually written once a target is
    /// known, via `flushPendingKeychainSaves()`.
    @MainActor
    private func requestPassword(for fileURL: URL, isRetry: Bool) async -> String? {
        await withCheckedContinuation { continuation in
            pendingPasswordRequest = PasswordPromptRequest(
                fileURL: fileURL,
                filename: fileURL.lastPathComponent,
                isRetry: isRetry,
                onSubmit: { [weak self] password, saveToKeychain in
                    guard let self else { return }
                    if saveToKeychain {
                        importSession.pendingKeychainSaves[fileURL] = password
                    }
                    pendingPasswordRequest = nil
                    continuation.resume(returning: password)
                },
                onCancel: { [weak self] in
                    self?.pendingPasswordRequest = nil
                    continuation.resume(returning: nil)
                }
            )
        }
    }

    /// Writes any passwords the user asked to save (via `requestPassword`'s
    /// "Save to Keychain" toggle) now that a target ledger is resolved. Safe to
    /// call repeatedly — it's a no-op once `pendingKeychainSaves` is empty or no
    /// target is resolved yet. Called from `parseFiles()` right after
    /// auto-match, and again at the top of `importTransactions()` to cover the
    /// manual-pick case (the Import button is only enabled once `selectedTarget`
    /// is non-nil, so by then this is guaranteed to flush).
    func flushPendingKeychainSaves() {
        guard case let .ledger(ledgerId) = importSession.selectedTarget,
              !importSession.pendingKeychainSaves.isEmpty else { return }
        for password in importSession.pendingKeychainSaves.values {
            passwordStore.save(password, for: ledgerId)
        }
        importSession.pendingKeychainSaves = [:]
    }

    /// Called when the password sheet is dismissed by any means other than the
    /// sheet's own Cancel/Continue buttons (e.g. Escape, click-away). Resumes the
    /// suspended continuation as a cancel so `parseWithPasswordRetry` doesn't hang.
    func cancelPendingPasswordRequest() {
        guard let request = pendingPasswordRequest else { return }
        pendingPasswordRequest = nil
        request.onCancel()
    }
}

struct PasswordPromptRequest: Identifiable {
    let id = UUID()
    let fileURL: URL
    let filename: String
    let isRetry: Bool
    let onSubmit: (String, Bool) -> Void
    let onCancel: () -> Void
}
