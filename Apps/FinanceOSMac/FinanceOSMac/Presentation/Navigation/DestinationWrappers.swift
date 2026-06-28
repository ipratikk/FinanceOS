import FinanceCore
import FinanceUI
import SwiftUI

struct AccountTransactionsDestinationView: View {
    let graphQLClient: ApolloGraphQLClient
    @State private var viewModel: AccountTransactionsDestinationViewModel

    init(ledgerId: UUID, graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
        _viewModel = State(initialValue: AccountTransactionsDestinationViewModel(
            ledgerId: ledgerId,
            graphQLClient: graphQLClient
        ))
    }

    var body: some View {
        Group {
            if let ledger = viewModel.ledger {
                AccountTransactionsView(
                    ledger: ledger,
                    viewModel: AccountTransactionsViewModel(
                        graphQLClient: graphQLClient
                    )
                )
                .navigationTitle(ledger.displayName)
            } else if !viewModel.isLoading {
                FDSLabel("Account not found")
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

struct CardTransactionsDestinationView: View {
    let graphQLClient: ApolloGraphQLClient
    @State private var viewModel: CardTransactionsDestinationViewModel

    init(ledgerId: UUID, graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
        _viewModel = State(initialValue: CardTransactionsDestinationViewModel(
            ledgerId: ledgerId,
            graphQLClient: graphQLClient
        ))
    }

    var body: some View {
        Group {
            if let ledger = viewModel.ledger {
                CardTransactionsView(
                    ledger: ledger,
                    viewModel: CardTransactionsViewModel(
                        graphQLClient: graphQLClient
                    )
                )
                .navigationTitle(ledger.displayName)
            } else if !viewModel.isLoading {
                FDSLabel("Card not found")
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

struct LedgerDetailDestinationView: View {
    @State private var viewModel: LedgerDetailViewModel

    init(ledgerId: UUID, graphQLClient: ApolloGraphQLClient) {
        _viewModel = State(initialValue: LedgerDetailViewModel(
            ledgerId: ledgerId,
            graphQLClient: graphQLClient
        ))
    }

    var body: some View {
        LedgerDetailView(viewModel: viewModel)
    }
}
