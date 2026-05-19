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
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                listHeader

                ForEach(
                    groupedCardsByBank.sorted(by: { $0.key < $1.key }),
                    id: \.key
                ) { bankName, cardRows in
                    bankSection(bankName: bankName, rows: cardRows)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Credit Cards")
                .font(AppTypography.headingLg)
                .foregroundStyle(.primary)
            Text("Manage and track your cards")
                .font(AppTypography.labelMedium)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardRowView(_ ledger: Ledger) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            cardRowHeader(ledger)
            Divider().opacity(0.3).padding(.horizontal, AppSpacing.lg)
            cardRowActions(ledger)
        }
        .background(.regularMaterial)
        .background(AppColors.surface.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColors.accent.opacity(0.15), lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.lg)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
    }

    private func cardRowHeader(_ ledger: Ledger) -> some View {
        let supportedCards = CardDatabase.supportedCards()
        let card = ledger.cardProduct.flatMap { product in
            supportedCards.first { $0.id == product }
        } ?? supportedCards.first { $0.name == ledger.displayName }

        return HStack(spacing: AppSpacing.lg) {
            cardArtwork(card: card)

            VStack(alignment: .leading, spacing: 8) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .font(AppTypography.bodyLg)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let cardType = ledger.cardType {
                        Text(cardType.uppercased())
                            .font(AppTypography.captionSm)
                            .tracking(0.4)
                    }
                    if !ledger.last4.isEmpty {
                        Text("•••• \(ledger.last4)")
                            .font(AppTypography.captionSm.monospacedDigit())
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
    }

    private func cardRowActions(_ ledger: Ledger) -> some View {
        HStack(spacing: AppSpacing.md) {
            Spacer()

            actionIconButton("plus", color: AppColors.accent) {
                let bank = viewModel.banks.first { $0.id == ledger.bankId }
                navigator.pendingImportTarget = .ledger(ledger.id)
                navigator.pendingImportSource = importSource(for: ledger, bank: bank)
                navigator.navigate(to: .importStatement)
            }

            actionIconButton("pencil", color: AppColors.accent) {
                navigator.present(.cardEdit(ledger))
            }

            actionIconButton("trash", color: AppColors.danger) {
                cardPendingDelete = ledger
            }
        }
        .padding(AppSpacing.md)
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(bankName)
                    .font(AppTypography.headlineMd)
                    .foregroundStyle(.primary)
                Text("\(rows.count) card\(rows.count == 1 ? "" : "s")")
                    .font(AppTypography.labelMedium)
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: AppSpacing.xs) {
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
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }

    private func cardArtwork(card: CardMetadata?) -> some View {
        Group {
            if let urlString = card?.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFit()
                    default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: 68, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .strokeBorder(AppColors.accent.opacity(0.08), lineWidth: 0.5)
        }
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "creditcard.fill")
                    .bodyMedium()
                    .foregroundStyle(.tertiary)
            }
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: AppSpacing.compact) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    skeletonRow
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(Color.white.opacity(0.04))
                .frame(width: 68, height: 44)
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
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(.ultraThinMaterial)
        }
    }
}
