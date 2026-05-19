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
        .background(AppColors.base)
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
                .font(AppTypography.headingXL)
                .foregroundColor(DesignTokens.Text.primary)
            Text("Manage and track your cards")
                .font(AppTypography.captionLgMedium)
                .tracking(0.3)
                .foregroundColor(DesignTokens.Text.secondary)
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
                    .font(AppTypography.bodySmSemibold)
                    .foregroundColor(DesignTokens.Text.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let cardType = ledger.cardType {
                        Text(cardType.uppercased())
                            .font(AppTypography.captionSmMedium)
                            .tracking(0.2)
                            .foregroundColor(DesignTokens.Text.secondary)
                    }
                    if !ledger.last4.isEmpty {
                        Text("•••• \(ledger.last4)")
                            .maskedAccount()
                            .foregroundColor(DesignTokens.Text.secondary)
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

            actionIconButton("plus", color: DesignTokens.Text.tertiary) {
                let bank = viewModel.banks.first { $0.id == ledger.bankId }
                navigator.pendingImportTarget = .ledger(ledger.id)
                navigator.pendingImportSource = importSource(for: ledger, bank: bank)
                navigator.navigate(to: .importStatement)
            }

            actionIconButton("pencil", color: DesignTokens.Text.tertiary) {
                navigator.present(.cardEdit(ledger))
            }

            actionIconButton("trash", color: AppColors.danger) {
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
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundColor(DesignTokens.Text.primary)
                Text("\(rows.count) card\(rows.count == 1 ? "" : "s")")
                    .font(AppTypography.captionLgMedium)
                    .foregroundColor(DesignTokens.Text.secondary)
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
                .font(AppTypography.captionLgSemibold)
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
                .fill(DesignTokens.Background.surfaceGlassThin)
                .frame(width: 56, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(DesignTokens.Background.surfaceGlassThin)
                    .frame(height: 11)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 3)
                    .fill(DesignTokens.Background.surfaceGlassThin)
                    .frame(height: 9)
                    .frame(maxWidth: 110)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Background.surfaceGlass)
        }
    }
}
