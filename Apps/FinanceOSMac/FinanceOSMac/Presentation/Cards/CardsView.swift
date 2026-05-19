import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct CardsView: View {
    @State private var viewModel: CardsViewModel
    @State private var cardPendingDelete: Ledger?
    @Environment(AppNavigator.self) private var navigator
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    init(
        viewModel: CardsViewModel,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
    }

    var body: some View {
        Group {
            if viewModel.cardRows.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                cardsList
            }
        }
        .background(Color(red: 0.039, green: 0.047, blue: 0.067))
        .navigationTitle("Cards")
        .onAppear {
            navigator.cardReloadCallback = {
                await viewModel.loadCards()
            }
        }
        .alert(
            "Delete \"\(cardPendingDelete?.displayName ?? "")\"?",
            isPresented: Binding(
                get: { cardPendingDelete != nil },
                set: { if !$0 { cardPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { cardPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let ledger = cardPendingDelete {
                    cardPendingDelete = nil
                    Task { await viewModel.deleteCard(id: ledger.id) }
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions.")
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
        .task {
            await viewModel.loadCards()
        }
    }

    private var cardsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                listHeader

                ForEach(
                    groupedCardsByBank.sorted(by: { $0.key < $1.key }),
                    id: \.key
                ) { bankName, cardRows in
                    bankSection(bankName: bankName, rows: cardRows)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Credit Cards")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
            Text("Manage and track your cards")
                .font(.system(size: 12, weight: .medium))
                .tracking(0.3)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardRowView(_ ledger: Ledger) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                cardRowHeader(ledger)
                Divider().opacity(0.2).padding(.horizontal, 12)
                cardRowActions(ledger)
            }
        }
    }

    private func cardRowHeader(_ ledger: Ledger) -> some View {
        return HStack(spacing: 16) {
            FDSCardArt(
                ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname,
                network: ledger.cardType?.uppercased() ?? "CARD",
                last4: ledger.last4
            )
            .frame(width: 76, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let cardType = ledger.cardType {
                        Text(cardType.uppercased())
                            .font(.system(size: 10, weight: .regular))
                            .tracking(0.2)
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                    }
                    if !ledger.last4.isEmpty {
                        Text("•••• \(ledger.last4)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                    }
                }
            }

            Spacer()
        }
        .padding(12)
    }

    private func cardRowActions(_ ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            Spacer()

            actionIconButton("plus", color: Color(red: 0.518, green: 0.541, blue: 0.580)) {
                let bank = viewModel.banks.first { $0.id == ledger.bankId }
                navigator.pendingImportTarget = .ledger(ledger.id)
                navigator.pendingImportSource = importSource(for: ledger, bank: bank)
                navigator.navigate(to: .importStatement)
            }

            actionIconButton("pencil", color: Color(red: 0.518, green: 0.541, blue: 0.580)) {
                navigator.present(.cardEdit(ledger))
            }

            actionIconButton("trash", color: Color(red: 1.0, green: 0.27, blue: 0.23)) {
                cardPendingDelete = ledger
            }
        }
        .padding(8)
    }

    private var emptyState: some View {
        FDSEmptyState(
            symbol: "creditcard",
            title: "No Cards",
            subtitle: "Import a statement to get started"
        )
    }
}

extension CardsView {
    private func bankSection(bankName: String, rows: [CardsViewModel.CardRow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bankName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                Text("\(rows.count) card\(rows.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            }

            VStack(spacing: 4) {
                ForEach(Array(rows.enumerated()), id: \.element.card.id) { _, row in
                    NavigationLink(value: DetailDestination.cardTransactions(row.card.id)) {
                        cardRowView(row.card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var groupedCardsByBank: [String: [CardsViewModel.CardRow]] {
        Dictionary(grouping: viewModel.cardRows) { cardRow in
            viewModel.banks.first { $0.id == cardRow.card.bankId }?.name ?? "Unknown"
        }
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
                .frame(width: 56, height: 36)
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
