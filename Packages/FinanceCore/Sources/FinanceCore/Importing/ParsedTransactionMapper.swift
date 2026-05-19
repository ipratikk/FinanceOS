import FinanceParsers
import Foundation

enum ParsedTransactionMapper {
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
                sourceFingerprint: parsed.sourceFingerprint
            )
        }
    }
}
