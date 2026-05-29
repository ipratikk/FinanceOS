import FinanceParsers
import Foundation

/// Converts a parser-layer `ParsedTransaction` into a domain `Transaction`, resolving ledger
/// ownership and sign convention.  Internal to the import pipeline; not exposed publicly.
enum ParsedTransactionMapper {
    /// Maps a single parsed transaction to a domain model bound to `target`.
    /// Sign rule: parser-positive amounts are debits (money leaving the account); negatives are credits.
    static func map(
        _ parsed: ParsedTransaction,
        target: TransactionImportTarget,
        ledgerKind: LedgerKind
    ) -> Transaction {
        let transactionType: TransactionType = parsed.amountMinorUnits >= 0 ? .debit : .credit
        let absoluteAmount = abs(parsed.amountMinorUnits)

        switch target {
        case let .ledger(ledgerId):
            return Transaction(
                ledgerId: ledgerId,
                accountID: ledgerKind == .bankAccount ? ledgerId : nil,
                cardID: ledgerKind == .creditCard ? ledgerId : nil,
                postedAt: parsed.postedAt,
                description: parsed.description,
                amountMinorUnits: absoluteAmount,
                currencyCode: parsed.currencyCode,
                transactionType: transactionType,
                sourceFingerprint: parsed.sourceFingerprint,
                closingBalanceMinorUnits: parsed.closingBalanceMinorUnits
            )
        }
    }
}
