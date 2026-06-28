import FinanceCore
import FinanceOSAPI
import FinanceParsers
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class CardsViewModel: AsyncLoadable, DeletableViewModel {
    struct CardRow: Identifiable {
        let id: UUID
        let card: Ledger
        let title: String
        let institutionName: String
        let linkedAccountName: String?

        var subtitle: String {
            if let linkedAccountName {
                return "\(institutionName) · \(linkedAccountName)"
            }
            return institutionName
        }
    }

    private let graphQLClient: ApolloGraphQLClient
    private let logger = FinanceLogger.userInterface

    var cardRows: [CardRow] = []
    var isLoading = false
    var banks: [Bank] = []
    var accounts: [Ledger] = []
    var deleteError: String?

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func loadCards() async {
        await withLoading(onError: { [self] error in
            logger.logError("Failed to load cards: {error}", ["error": error.localizedDescription])
        }, {
            let data = try await graphQLClient.fetch(query: GetLedgersQuery())
            let bankData = try await graphQLClient.fetch(query: GetBanksQuery())
            let allLedgers = data.ledgers.map(GraphQLMappings.mapLedger)
            self.banks = bankData.banks.map(GraphQLMappings.mapBank)
            let cards = allLedgers.filter { $0.kind == .creditCard }
            self.accounts = allLedgers.filter { $0.kind == .bankAccount }
            cardRows = makeCardRows(cards: cards, accounts: self.accounts, banks: self.banks)
        })
    }

    func updateCard(_ card: Ledger) async {
        do {
            let input = UpdateLedgerInput(
                displayName: .some(card.displayName),
                kind: .some(.init(FinanceOSAPI.LedgerKind.creditCard)),
                last4: card.last4.isEmpty ? .null : .some(card.last4)
            )
            _ = try await graphQLClient.perform(mutation: UpdateLedgerMutation(id: card.id.uuidString, input: input))
            await loadCards()
        } catch {
            logger.logError(
                "Failed to update card: {error}",
                ["cardId": card.id.uuidString, "error": error.localizedDescription]
            )
        }
    }

    func deleteCard(id: UUID) async {
        await performDelete({
            logger.logDebug("Deleting card", ["cardId": id.uuidString])
            _ = try await graphQLClient.perform(mutation: DeleteLedgerMutation(id: id.uuidString))
            logger.logInfo("Card deleted successfully", ["cardId": id.uuidString])
        }, onError: { [self] error in
            logger.logError(
                "Delete card failed: {error}",
                ["cardId": id.uuidString, "error": error.localizedDescription]
            )
        }, onSuccess: loadCards)
    }

    func convertToAccount(_ card: Ledger) async {
        do {
            let input = UpdateLedgerInput(
                displayName: .some(card.displayName),
                kind: .some(.init(FinanceOSAPI.LedgerKind.bankAccount)),
                last4: card.last4.isEmpty ? .null : .some(card.last4)
            )
            _ = try await graphQLClient.perform(mutation: UpdateLedgerMutation(id: card.id.uuidString, input: input))
            await loadCards()
        } catch {
            logger.logError(
                "Failed to convert card to account: {error}",
                ["cardId": card.id.uuidString, "error": error.localizedDescription]
            )
        }
    }

    private func makeCardRows(
        cards: [Ledger],
        accounts: [Ledger],
        banks: [Bank]
    ) -> [CardRow] {
        let accountsByID = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
        let banksByID = Dictionary(uniqueKeysWithValues: banks.map { ($0.id, $0) })

        return cards.map { card in
            let bankName = banksByID[card.bankId]?.name ?? "Unknown Bank"
            let displayName = card.nickname.isEmpty ? card.displayName : card.nickname
            let maskLast4 = card.last4.isEmpty ? "" : " ••••\(card.last4)"
            let title = "\(bankName) \(displayName)\(maskLast4)".trimmingCharacters(in: .whitespaces)

            return CardRow(
                id: card.id,
                card: card,
                title: title,
                institutionName: bankName,
                linkedAccountName: card.linkedLedgerId.flatMap { accountsByID[$0]?.displayName }
            )
        }
    }

    func statementSource(for ledger: Ledger) -> StatementSource? {
        let bank = banks.first { $0.id == ledger.bankId }
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
}
