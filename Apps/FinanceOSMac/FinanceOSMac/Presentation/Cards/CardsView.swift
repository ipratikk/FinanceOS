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
        List {
            ForEach(
                groupedCardsByBank.sorted(by: { $0.key < $1.key }),
                id: \.key
            ) { bankName, cardRows in
                Section {
                    ForEach(cardRows, id: \.card.id) { cardRow in
                        NavigationLink(value: DetailDestination.cardTransactions(cardRow.card.id)) {
                            cardRowView(cardRow.card)
                        }
                        .listRowBackground(AppColors.surface)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                cardPendingDelete = cardRow.card
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button("Edit") { navigator.present(.cardEdit(cardRow.card)) }
                            Button("Delete", role: .destructive) {
                                cardPendingDelete = cardRow.card
                            }
                        }
                    }
                } header: {
                    bankSectionHeader(bankName)
                }
            }
        }
        .listStyle(.plain)
        .background(AppColors.base)
        .scrollContentBackground(.hidden)
    }

    private var groupedCardsByBank: [String: [CardsViewModel.CardRow]] {
        Dictionary(grouping: viewModel.cardRows) { cardRow in
            viewModel.banks.first { $0.id == cardRow.card.bankId }?.name ?? "Unknown"
        }
    }

    private func networkLogoURL(for cardType: String) -> URL? {
        let urls: [String: String] = [
            "visa": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/1200px-Visa_Inc._logo.svg.png",
            "mastercard": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1024px-Mastercard-logo.svg.png",
            "rupay": "https://upload.wikimedia.org/wikipedia/en/6/6d/RuPay_logo.svg",
            "discover": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Discover_Card_logo.svg/1024px-Discover_Card_logo.svg.png"
        ]
        return urls[cardType.lowercased()].flatMap { URL(string: $0) }
    }

    private func bankSectionHeader(_ bankName: String) -> some View {
        HStack(spacing: 8) {
            AsyncImage(url: bankLogoURL(for: bankName)) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                case .failure:
                    Text(bankName)
                        .labelSmall()
                        .foregroundColor(AppColors.textTertiary)
                default:
                    Text(bankName)
                        .labelSmall()
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .frame(width: 50, height: 20)

            Text(bankName)
                .headingSmall()
        }
    }

    private func bankLogoURL(for issuer: String) -> URL? {
        let localLogos: [String: String] = [
            "HDFC Bank": "bank-logos/hdfc",
            "ICICI Bank": "bank-logos/icici"
        ]

        if let localAsset = localLogos[issuer],
           let assetURL = Bundle.module.url(forResource: localAsset, withExtension: nil) {
            return assetURL
        }

        return nil
    }

    func cardRowView(_ ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .monoAmount()

                HStack(spacing: 6) {
                    if let cardType = ledger.cardType {
                        AsyncImage(url: networkLogoURL(for: cardType)) { phase in
                            switch phase {
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 10)
                            default:
                                EmptyView()
                            }
                        }
                        .frame(width: 20, height: 10)

                        Text(cardType.uppercased())
                            .labelSmall()
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            Spacer()

            Text("••••\(ledger.last4)")
                .monoAmountSmall()
                .foregroundColor(AppColors.accent)
        }
        .padding(AppSpacing.sm)
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
