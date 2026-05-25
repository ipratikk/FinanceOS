import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct CardsView: View {
    @State private var viewModel: CardsViewModel
    @State private var cardPendingDelete: Ledger?
    @State private var hoveredCardId: UUID?
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
            FDSLabel("This will permanently delete this card and all associated transactions.")
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("OK") { viewModel.deleteError = nil }
        } message: {
            if let error = viewModel.deleteError {
                FDSLabel(error)
            }
        }
        .task {
            await viewModel.loadCards()
        }
    }

    private var cardsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                listHeader

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.cardRows, id: \.card.id) { row in
                        cardGridItem(row)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Card Management")
                .font(AppTypography.displayLarge)
                .foregroundColor(AppColors.Text.primary)
            FDSLabel("Manage and track your cards")
                .font(AppTypography.captionSm)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    private func cardGridItem(_ row: CardsViewModel.CardRow) -> some View {
        let ledger = row.card
        let bank = viewModel.banks.first { $0.id == ledger.bankId }

        return ZStack(alignment: .bottom) {
            NavigationLink(value: DetailDestination.cardTransactions(ledger.id)) {
                CardDisplayPreview(
                    cardName: ledger.displayName,
                    cardNickName: ledger.nickname,
                    bankName: bank?.bank.displayName,
                    selectedBank: bank?.bank,
                    cardholderName: ledger.ownerName,
                    cardNetwork: ledger.cardType ?? .other,
                    first4: ledger.bin.map { String($0.prefix(4)) } ?? "",
                    last4: ledger.last4,
                    bankLogo: bank?.logoAssetName
                )
            }
            .buttonStyle(.plain)

            cardItemActions(ledger: ledger, bank: bank)
                .padding(.bottom, AppSpacing.compact)
                .opacity(hoveredCardId == ledger.id ? 1 : 0)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredCardId = hovering ? ledger.id : nil
            }
        }
    }

    private func cardItemActions(ledger: Ledger, bank: Bank?) -> some View {
        HStack(spacing: AppSpacing.compact) {
            actionIconButton("plus", color: AppColors.Text.primary) {
                navigator.pendingImportTarget = .ledger(ledger.id)
                navigator.pendingImportSource = importSource(for: ledger, bank: bank)
                navigator.navigate(to: .importStatement)
            }
            actionIconButton("pencil", color: AppColors.Text.primary) {
                navigator.present(.cardEdit(ledger))
            }
            actionIconButton("trash", color: AppColors.danger) {
                cardPendingDelete = ledger
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.tight)
        .glassPill()
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.Glass.thinTint)
                        .frame(height: 20)
                        .frame(maxWidth: 200)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.Glass.thinTint)
                        .frame(height: 12)
                        .frame(maxWidth: 120)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(0 ..< 6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppColors.Glass.surface)
                            .aspectRatio(1.586, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }
}
