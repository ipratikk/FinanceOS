import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionRowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_transaction_row_debit() {
        let view = FDSTransactionRow(
            merchant: "Whole Foods Market",
            subtitle: "May 18 · Checking",
            amount: "$65.43",
            isDebit: true
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 60))
    }

    func test_transaction_row_credit() {
        let view = FDSTransactionRow(
            merchant: "Salary Deposit",
            subtitle: "May 18 · Checking",
            amount: "$5,000.00",
            isDebit: false
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 60))
    }

    func test_transaction_row_long_description() {
        let view = FDSTransactionRow(
            merchant: "Amazon Marketplace Purchase Order #12345",
            subtitle: "May 18 · Amex Premium",
            amount: "$145.67",
            isDebit: true
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 60))
    }
}
