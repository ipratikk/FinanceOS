import FinanceCore
import FinanceUI
import Observation

@Observable
@MainActor
final class CardSelectionViewModel {
    private(set) var allCards: [CardMetadata] = []
    private(set) var allIssuers: [String] = []
    var selectedIssuer: String?
    var searchText = ""

    func load() {
        allCards = CardDatabase.supportedCards()
        allIssuers = CardDatabase.issuers()
    }

    var filteredCards: [CardMetadata] {
        let base = selectedIssuer.map { issuer in allCards.filter { $0.issuer == issuer } } ?? allCards
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
}
