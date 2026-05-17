import FinanceCore
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
            Text(
                "This will permanently delete this card and all associated transactions. This cannot be undone."
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
        .task {
            await viewModel.loadCards()
        }
    }

    var cardsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(
                    groupedCardsByBank.sorted(by: { $0.key < $1.key }),
                    id: \.key
                ) { bankName, cardRows in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        bankSectionHeader(bankName)

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            ForEach(cardRows, id: \.card.id) { cardRow in
                                NavigationLink(value: DetailDestination.cardTransactions(cardRow.card.id)) {
                                    cardRowView(cardRow.card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.base)
    }

    private var groupedCardsByBank: [String: [CardsViewModel.CardRow]] {
        Dictionary(grouping: viewModel.cardRows) { cardRow in
            viewModel.banks.first { $0.id == cardRow.card.bankId }?.name ?? "Unknown"
        }
    }

    private func networkLogo(for cardType: String) -> NSImage? {
        let assetNames: [String: String] = [
            "visa": "visa",
            "mastercard": "mastercard",
            "amex": "amex",
            "rupay": "rupay",
            "diners": "diners"
        ]

        if let assetName = assetNames[cardType.lowercased()],
           let nsImage = NSImage(named: assetName)
        {
            return nsImage
        }

        return nil
    }

    private func bankSectionHeader(_ bankName: String) -> some View {
        HStack(spacing: 8) {
            if let logo = bankLogo(for: bankName) {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 20)
            }

            Text(bankName)
                .headingSmall()
        }
    }

    private func bankLogo(for issuer: String) -> NSImage? {
        let assetNames: [String: String] = [
            "HDFC Bank": "hdfc-logo",
            "ICICI Bank": "icici-logo"
        ]

        if let assetName = assetNames[issuer],
           let nsImage = NSImage(named: assetName)
        {
            return nsImage
        }

        return nil
    }

    func cardRowView(_ ledger: Ledger) -> some View {
        let supportedCards = CardDatabase.supportedCards()
        let card = ledger.cardProduct.flatMap { product in
            supportedCards.first { $0.id == product }
        } ?? supportedCards.first { $0.name == ledger.displayName }

        return HStack(spacing: AppSpacing.md) {
            // Card image
            AsyncImage(url: URL(string: card?.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.glass)
                        .frame(width: 56, height: 36)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 36)
                        .cornerRadius(AppRadius.sm)
                case .failure:
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(AppColors.glass)
                        .frame(width: 56, height: 36)
                        .overlay(
                            Image(systemName: "creditcard")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.textTertiary)
                        )
                @unknown default:
                    EmptyView()
                }
            }

            // Card info
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .monoAmount()
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xxs) {
                    if let cardType = ledger.cardType {
                        if let logo = networkLogo(for: cardType) {
                            Image(nsImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 8)
                        }

                        Text("••••\(ledger.last4)")
                            .labelSmall()
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Menu
            Menu {
                Button("Edit") { navigator.present(.cardEdit(ledger)) }
                Button("Delete", role: .destructive) { cardPendingDelete = ledger }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.sm)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.borderSubtle, lineWidth: 0.5)
        )
        .cornerRadius(AppRadius.md)
        .onAppear {
            print(
                "[CardsView] '\(ledger.displayName)' cardProduct=\(ledger.cardProduct ?? "nil") image=\(card?.imageURL ?? "nil")"
            )
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text("No Cards")
                    .headingSmall()

                Text("Import a statement to get started")
                    .caption()
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.surface2)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surface2)
                            .frame(height: 12)
                            .frame(maxWidth: 120)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.surface2)
                            .frame(height: 10)
                            .frame(maxWidth: 80)
                    }

                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)
            }
        }
        .padding(AppSpacing.md)
    }
}
