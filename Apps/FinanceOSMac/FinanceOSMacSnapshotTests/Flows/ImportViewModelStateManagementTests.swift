import FinanceCore
@testable import FinanceOSMac
import Foundation
import XCTest

/// Regression coverage for `ImportViewModel.autoSelectMatchingTarget()`.
///
/// This is a plain logic test (no rendering) — deliberately not a `SnapshotTestable`
/// subclass. It lives in `FinanceOSMacSnapshotTests` because that is the only test
/// target currently wired up for `FinanceOSMac`.
@MainActor
final class ImportViewModelStateManagementTests: XCTestCase {
    /// A bank + bank-account ledger pair with matching ids and a last4 that will
    /// confidently (`confidence == 1.0`) resolve via `ImportTargetMatcher`.
    /// `PreviewLedgers`/`PreviewBanks` are not used here because their fixture bank
    /// ids do not line up (`PreviewLedgers` hardcodes `bankId` `...0099`, which does
    /// not match `PreviewBanks.hdfc()`'s id `...0001`), so the matcher would always
    /// return nil regardless of the guard under test.
    private func makeMatchableBankAndLedger() -> (bank: Bank, ledger: Ledger) {
        let bankId = UUID()
        let bank = Bank(id: bankId, bank: .hdfc)
        let ledger = Ledger(
            id: UUID(),
            bankId: bankId,
            kind: .bankAccount,
            displayName: "HDFC Checking",
            last4: "1234"
        )
        return (bank, ledger)
    }

    private func makeMatchingStatement() -> ParsedStatement {
        ParsedStatement(bankName: "HDFC Bank", accountName: "Test", accountLast4: "1234")
    }

    func test_autoSelectMatchingTarget_doesNotOverwritePreSelectedTarget() async {
        let (bank, ledger) = makeMatchableBankAndLedger()
        let preSelected = TransactionImportTarget.ledger(UUID())

        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient(), initialTarget: preSelected)
        viewModel.banks = [bank]
        viewModel.ledgers = [ledger]
        viewModel.parsedStatements = [makeMatchingStatement()]

        // Sanity: the matcher would confidently resolve to a *different* target than
        // the pre-selected one, so this test actually exercises the guard.
        let wouldMatch = FinanceCore.ImportTargetMatcher.bestTarget(
            for: makeMatchingStatement(),
            ledgers: [ledger],
            banks: [bank]
        )
        XCTAssertEqual(wouldMatch, .ledger(ledger.id))
        XCTAssertNotEqual(wouldMatch, preSelected)

        await viewModel.autoSelectMatchingTarget()

        XCTAssertEqual(viewModel.selectedTarget, preSelected)
    }

    func test_autoSelectMatchingTarget_setsTargetWhenNoneSelected() async {
        let (bank, ledger) = makeMatchableBankAndLedger()

        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        viewModel.banks = [bank]
        viewModel.ledgers = [ledger]
        viewModel.parsedStatements = [makeMatchingStatement()]

        XCTAssertNil(viewModel.selectedTarget)

        await viewModel.autoSelectMatchingTarget()

        XCTAssertEqual(viewModel.selectedTarget, .ledger(ledger.id))
    }
}
