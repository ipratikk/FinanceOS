import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSTransactionRowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_row_debit_with_symbol() {
        let view = FDSTransactionRow(
            merchant: "Whole Foods Market",
            categorySymbol: "fork.knife",
            subtitle: "May 18 · Checking",
            amount: "₹65.43",
            isDebit: true
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_row_credit_with_symbol() {
        let view = FDSTransactionRow(
            merchant: "Salary Deposit",
            categorySymbol: "arrow.down.left.circle.fill",
            subtitle: "May 1 · Checking",
            amount: "₹5,000.00",
            isDebit: false
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_row_with_account_chip() {
        let view = FDSTransactionRow(
            merchant: "Starbucks",
            categorySymbol: "cup.and.saucer.fill",
            subtitle: "May 18",
            amount: "₹6.25",
            isDebit: true,
            accountChip: .init(bankName: "HDFC", last4: "1234")
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 96))
    }

    func test_row_with_running_balance() {
        let view = FDSTransactionRow(
            merchant: "Target",
            categorySymbol: "bag.fill",
            subtitle: "May 18",
            amount: "₹145.67",
            isDebit: true,
            runningBalance: "₹12,340.00"
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 96))
    }

    func test_row_long_merchant_name() {
        let view = FDSTransactionRow(
            merchant: "Amazon Marketplace Purchase Order #12345",
            subtitle: "May 18 · Amex ••••9999",
            amount: "₹1,499.00",
            isDebit: true
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_row_initial_avatar_fallback() {
        let view = FDSTransactionRow(
            merchant: "BookMyShow",
            subtitle: "May 15 · ICICI ••••5678",
            amount: "₹299.00",
            isDebit: true
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_rows_in_card_container() {
        let view = FDSCard(cornerRadius: 12, padded: false) {
            VStack(spacing: 0) {
                FDSTransactionRow(
                    merchant: "Whole Foods Market",
                    categorySymbol: "fork.knife",
                    subtitle: "May 18 · Checking",
                    amount: "₹65.43",
                    isDebit: true
                )
                Divider().opacity(0.15)
                FDSTransactionRow(
                    merchant: "Salary Deposit",
                    categorySymbol: "arrow.down.left.circle.fill",
                    subtitle: "May 1 · Checking",
                    amount: "₹5,000.00",
                    isDebit: false
                )
                Divider().opacity(0.15)
                FDSTransactionRow(
                    merchant: "Starbucks",
                    categorySymbol: "cup.and.saucer.fill",
                    subtitle: "Apr 30 · HDFC ••••1234",
                    amount: "₹6.25",
                    isDebit: true
                )
            }
        }
        verifyFDSComponent(view, size: CGSize(width: 520, height: 280))
    }
}
