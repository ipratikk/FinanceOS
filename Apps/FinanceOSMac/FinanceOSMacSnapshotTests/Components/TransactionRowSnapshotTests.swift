import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionRowSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_transaction_row_debit() {
        let view = FDSTransactionRow(
            merchant: "Whole Foods Market",
            categorySymbol: "fork.knife",
            subtitle: "May 18 · Checking",
            amount: "₹65.43",
            isDebit: true
        )
        verifyFDSComponent(view, size: CGSize(width: 420, height: 80))
    }

    func test_transaction_row_credit() {
        let view = FDSTransactionRow(
            merchant: "Salary Deposit",
            categorySymbol: "arrow.down.left.circle.fill",
            subtitle: "May 18 · Checking",
            amount: "₹5,000.00",
            isDebit: false
        )
        verifyFDSComponent(view, size: CGSize(width: 420, height: 80))
    }

    func test_transaction_row_long_description() {
        let view = FDSTransactionRow(
            merchant: "Amazon Marketplace Purchase Order #12345",
            subtitle: "May 18 · Amex Premium",
            amount: "₹145.67",
            isDebit: true
        )
        verifyFDSComponent(view, size: CGSize(width: 420, height: 80))
    }

    func test_transaction_row_with_account_chip() {
        let view = FDSTransactionRow(
            merchant: "Starbucks",
            categorySymbol: "cup.and.saucer.fill",
            subtitle: "May 18",
            amount: "₹6.25",
            isDebit: true,
            accountChip: .init(bankName: "HDFC", last4: "1234")
        )
        verifyFDSComponent(view, size: CGSize(width: 420, height: 88))
    }

    func test_transaction_row_with_running_balance() {
        let view = FDSTransactionRow(
            merchant: "Target",
            categorySymbol: "bag.fill",
            subtitle: "May 18",
            amount: "₹145.67",
            isDebit: true,
            runningBalance: "₹12,340.00"
        )
        verifyFDSComponent(view, size: CGSize(width: 420, height: 88))
    }
}
