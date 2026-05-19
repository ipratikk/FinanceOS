import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel
    @State private var accountPendingDelete: Ledger?
    @Environment(AppNavigator.self) private var navigator
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    init(
        viewModel: AccountsViewModel,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
    }

    var body: some View {
        Group {
            if viewModel.accounts.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                accountsList
            }
        }
        .background(Color(red: 0.039, green: 0.047, blue: 0.067))
        .navigationTitle("Accounts")
        .alert(
            "Delete \"\(accountPendingDelete?.displayName ?? "")\"?",
            isPresented: Binding(
                get: { accountPendingDelete != nil },
                set: { if !$0 { accountPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { accountPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let ledger = accountPendingDelete {
                    accountPendingDelete = nil
                    Task { await viewModel.deleteAccount(id: ledger.id) }
                }
            }
        } message: {
            Text(
                "This will permanently delete this account and all associated transactions. This cannot be undone."
            )
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("OK") { viewModel.deleteError = nil }
        } message: {
            if let error = viewModel.deleteError {
                Text(error)
            }
        }
        .onAppear {
            navigator.accountReloadCallback = {
                await viewModel.loadAccounts()
            }
        }
        .task {
            await viewModel.loadAccounts()
        }
    }

    private var accountsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                listHeader

                ForEach(
                    groupedAccountsByBank.sorted(by: { $0.key < $1.key }),
                    id: \.key
                ) { bankName, ledgers in
                    bankSection(bankName: bankName, ledgers: ledgers)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bank Accounts")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
            Text("Manage your accounts and balances")
                .font(.system(size: 12, weight: .medium))
                .tracking(0.3)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        FDSEmptyState(
            symbol: "building.columns",
            title: "No Accounts",
            subtitle: "Import a statement to get started"
        )
    }
}

extension AccountsView {
    private func bankSection(bankName: String, ledgers: [Ledger]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bankName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                Text("\(ledgers.count) account\(ledgers.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }

            VStack(spacing: 4) {
                ForEach(Array(ledgers.enumerated()), id: \.element.id) { _, ledger in
                    NavigationLink(value: DetailDestination.accountTransactions(ledger.id)) {
                        accountRow(ledger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var groupedAccountsByBank: [String: [Ledger]] {
        Dictionary(grouping: viewModel.accounts) { ledger in
            viewModel.banks.first { $0.id == ledger.bankId }?.name ?? "Unknown"
        }
    }

    private func accountRow(_ ledger: Ledger) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                accountRowHeader(ledger)
                Divider().opacity(0.2).padding(.horizontal, 12)
                accountRowActions(ledger)
            }
        }
    }

    private func accountRowHeader(_ ledger: Ledger) -> some View {
        let bank = viewModel.banks.first { $0.id == ledger.bankId }
        let balance = viewModel.balancesByAccount[ledger.id]

        return HStack(spacing: 16) {
            FDSBankMark(bank?.bank ?? .hdfc)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text((ledger.accountType ?? "Account").capitalized)
                        .font(.system(size: 10, weight: .regular))
                    if !ledger.last4.isEmpty {
                        Text("•••• \(ledger.last4)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                    }
                }
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }

            Spacer()

            if let balance {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(balance.formattedBalance)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.19, green: 0.82, blue: 0.35))
                }
            }
        }
        .padding(12)
    }

    private func accountRowActions(_ ledger: Ledger) -> some View {
        let bank = viewModel.banks.first { $0.id == ledger.bankId }

        return HStack(spacing: 12) {
            Spacer()

            actionIconButton("plus", color: Color(red: 0.518, green: 0.541, blue: 0.580)) {
                navigator.pendingImportTarget = .ledger(ledger.id)
                navigator.pendingImportSource = importSource(for: ledger, bank: bank)
                navigator.navigate(to: .importStatement)
            }

            actionIconButton("pencil", color: Color(red: 0.518, green: 0.541, blue: 0.580)) {
                navigator.present(.accountEdit(ledger))
            }

            actionIconButton("trash", color: Color(red: 1.0, green: 0.27, blue: 0.23)) {
                accountPendingDelete = ledger
            }
        }
        .padding(8)
    }

    private func importSource(for ledger: Ledger, bank: Bank?) -> StatementSource? {
        guard let bankEnum = bank?.bank else { return nil }
        switch (bankEnum, ledger.kind) {
        case (.hdfc, .bankAccount): return .hdfcBank
        case (.hdfc, .creditCard): return .hdfcCard
        case (.icici, .bankAccount): return .iciciBank
        case (.icici, .creditCard): return .iciciCard
        case (.amex, _): return .amex
        default: return nil
        }
    }

    private func actionIconButton(
        _ symbol: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 32, minHeight: 32)
        .contentShape(Rectangle())
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    skeletonRow
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.04))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 11)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 9)
                    .frame(maxWidth: 110)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        }
    }
}
