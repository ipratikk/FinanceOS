import FinanceCore
@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - Helpers

private func makeTxn(
    id: UUID = UUID(),
    description: String,
    amount: Int64,
    type: TransactionType,
    date: Date = Date(timeIntervalSince1970: 1_000_000)
) -> Transaction {
    Transaction(
        id: id, ledgerId: UUID(), accountID: nil, cardID: nil,
        postedAt: date, description: description,
        amountMinorUnits: amount, currencyCode: "INR",
        transactionType: type
    )
}

// MARK: - CreditCardPaymentReconciler

@Test func reconciler_matchesAmexPair() {
    let bankDebit = makeTxn(
        description: "UPI-AMERICAN EXPRESS-AEBC373008620701005@SC",
        amount: 1_000_000, type: .debit
    )
    let cardCredit = makeTxn(
        description: "PAYMENT RECEIVED. THANK YOU",
        amount: 1_000_000, type: .credit,
        date: Date(timeIntervalSince1970: 1_000_000 + 86400)
    )
    let pairs = CreditCardPaymentReconciler().reconcile(
        bankDebits: [bankDebit],
        cardCredits: [cardCredit]
    )
    #expect(pairs.count == 1)
    #expect(pairs[0].bankDebitId == bankDebit.id)
    #expect(pairs[0].cardCreditId == cardCredit.id)
    #expect(pairs[0].discrepancy == 0)
}

@Test func reconciler_matchesWithCREDCashbackDelta() {
    let bankDebit = makeTxn(
        description: "UPI-CRED CLUB-CRED.CLUB@AXISB",
        amount: 940_025, type: .debit
    )
    let cardCredit = makeTxn(
        description: "BBPS Payment received",
        amount: 940_000, type: .credit,
        date: Date(timeIntervalSince1970: 1_000_000 + 3600)
    )
    let pairs = CreditCardPaymentReconciler().reconcile(bankDebits: [bankDebit], cardCredits: [cardCredit])
    #expect(pairs.count == 1)
    #expect(abs(pairs[0].discrepancy) <= 5000)
}

@Test func reconciler_noMatch_outsideDateWindow() {
    let bankDebit = makeTxn(
        description: "UPI-AMERICAN EXPRESS-AEBC373008620701005@SC",
        amount: 1_000_000, type: .debit
    )
    let cardCredit = makeTxn(
        description: "PAYMENT RECEIVED. THANK YOU",
        amount: 1_000_000, type: .credit,
        date: Date(timeIntervalSince1970: 1_000_000 + 86400 * 5)
    )
    let pairs = CreditCardPaymentReconciler().reconcile(bankDebits: [bankDebit], cardCredits: [cardCredit])
    #expect(pairs.isEmpty)
}

@Test func reconciler_noMatch_amountTooFarOff() {
    let bankDebit = makeTxn(
        description: "UPI-CRED CLUB-CRED.CLUB@AXISB",
        amount: 1_000_000, type: .debit
    )
    let cardCredit = makeTxn(
        description: "BBPS Payment received",
        amount: 500_000, type: .credit
    )
    let pairs = CreditCardPaymentReconciler().reconcile(bankDebits: [bankDebit], cardCredits: [cardCredit])
    #expect(pairs.isEmpty)
}
