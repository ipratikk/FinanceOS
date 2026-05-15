import FinanceParsers
import Foundation

enum ParsedTransactionMapper {
    static func map(_ parsed: ParsedTransaction, target: TransactionImportTarget) -> Transaction {
        let transactionType: TransactionType = parsed.amountMinorUnits >= 0 ? .credit : .debit
        let absoluteAmount = abs(parsed.amountMinorUnits)

        switch target {
        case let .account(accountID):
            return Transaction(
                accountID: accountID,
                postedAt: parsed.postedAt,
                description: parsed.description,
                amountMinorUnits: absoluteAmount,
                currencyCode: parsed.currencyCode,
                transactionType: transactionType,
                sourceFingerprint: parsed.sourceFingerprint
            )

        case let .card(cardID):
            return Transaction(
                cardID: cardID,
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
