import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionRowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_transaction_row_debit() {
        let view = TransactionRowView(
            description: "Whole Foods Market",
            amount: "$65.43",
            date: "May 18",
            source: "Checking",
            isDebit: true
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 60))
    }

    func test_transaction_row_credit() {
        let view = TransactionRowView(
            description: "Salary Deposit",
            amount: "$5,000.00",
            date: "May 18",
            source: "Checking",
            isDebit: false
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 60))
    }

    func test_transaction_row_long_description() {
        let view = TransactionRowView(
            description: "Amazon Marketplace Purchase Order #12345",
            amount: "$145.67",
            date: "May 18",
            source: "Amex Premium",
            isDebit: true
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 60))
    }
}
