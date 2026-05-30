import FinanceCore
import Foundation
import GRDB
import Testing

@testable import FinanceIntelligence

@Suite("GraphBuilder — knowledge graph topology")
struct GraphBuilderTests {
    // MARK: - Helpers

    private func makeStore() throws -> GraphStore {
        let db = try DatabaseQueue()
        try db.write { database in
            try database.create(table: "knowledge_graph_nodes") { table in
                table.column("id", .text).primaryKey()
                table.column("nodeType", .text).notNull()
                table.column("externalId", .text).notNull()
                table.column("label", .text).notNull()
                table.column("properties", .text).notNull().defaults(to: "{}")
                table.column("createdAt", .datetime).notNull()
            }
            try database.create(index: "idx_kgn_ext",
                                on: "knowledge_graph_nodes",
                                columns: ["nodeType", "externalId"], unique: true)
            try database.create(table: "knowledge_graph_edges") { table in
                table.column("id", .text).primaryKey()
                table.column("fromNodeId", .text).notNull()
                table.column("toNodeId", .text).notNull()
                table.column("edgeType", .text).notNull()
                table.column("weight", .double).notNull().defaults(to: 1.0)
                table.column("observationCount", .integer).notNull().defaults(to: 1)
                table.column("lastObservedAt", .datetime).notNull()
                table.column("createdAt", .datetime).notNull()
            }
            try database.create(index: "idx_kge_unique",
                                on: "knowledge_graph_edges",
                                columns: ["fromNodeId", "toNodeId", "edgeType"], unique: true)
        }
        let repo = GRDBGraphRepository(dbWriter: db)
        return GraphStore(repository: repo)
    }

    private func makeTxn(
        id: UUID = UUID(),
        description: String,
        amount: Int64,
        type: TransactionType,
        ledgerId: UUID = UUID(),
        categoryId: String = "transfers"
    ) -> Transaction {
        Transaction(
            id: id,
            ledgerId: ledgerId,
            accountID: nil,
            cardID: nil,
            postedAt: Date(),
            description: description,
            amountMinorUnits: amount,
            currencyCode: "INR",
            transactionType: type,
            categoryId: categoryId,
            merchantName: nil
        )
    }

    private func makeEnriched(txn: Transaction, merchant: String, categoryId: String) -> EnrichedTransaction {
        let features = TransactionFeatureExtractor().extract(from: txn)
        return EnrichedTransaction(
            transaction: txn,
            merchantCandidate: MerchantCandidate(MerchantCandidateInput(
                rawDescription: txn.description,
                cleanedDescription: merchant,
                canonicalName: merchant,
                confidence: 0.9,
                source: .alias
            )),
            categoryPrediction: CategoryPrediction(
                categoryId: categoryId,
                subcategoryId: nil,
                displayName: categoryId.capitalized,
                confidence: 0.9,
                alternatives: [],
                source: .mlModel,
                modelVersion: "test",
                taxonomyVersion: "1.0.0"
            ),
            intentPrediction: IntentPrediction(
                intent: .transfer,
                confidence: 0.8,
                source: .ruleEngine
            ),
            features: features,
            isUserCorrected: false
        )
    }

    // MARK: - Tests

    @Test("Single debit creates transaction→merchant PAID_TO edge")
    func singleDebitCreatesPaidToEdge() async throws {
        let store = try makeStore()
        let builder = GraphBuilder(store: store)

        let txn = makeTxn(description: "UPI-BLINKIT", amount: 50000, type: .debit)
        let enriched = makeEnriched(txn: txn, merchant: "Blinkit", categoryId: "groceries")
        try await builder.build(from: [enriched])

        let txnNode = try await store.node(externalId: txn.id.uuidString, type: .transaction)
        #expect(txnNode != nil)

        let merchantNode = try await store.node(externalId: "blinkit", type: .merchant)
        #expect(merchantNode != nil)

        let edges = try await store.edges(from: txnNode!.id)
        let paidToEdges = edges.filter { $0.edgeType == .paidTo }
        #expect(!paidToEdges.isEmpty)
    }

    @Test("Credit creates PAID_FROM edge")
    func creditCreatesPaidFromEdge() async throws {
        let store = try makeStore()
        let builder = GraphBuilder(store: store)

        let txn = makeTxn(description: "NEFT CR-PAYPAL SALARY", amount: 15000000, type: .credit)
        let enriched = makeEnriched(txn: txn, merchant: "PayPal", categoryId: "income")
        try await builder.build(from: [enriched])

        let txnNode = try await store.node(externalId: txn.id.uuidString, type: .transaction)
        let edges = try await store.edges(from: txnNode!.id)
        let paidFromEdges = edges.filter { $0.edgeType == .paidFrom }
        #expect(!paidFromEdges.isEmpty)
    }

    @Test("Repeated same merchant increments edge observation count")
    func repeatedMerchantIncrementsObservationCount() async throws {
        let store = try makeStore()
        let builder = GraphBuilder(store: store)

        let txn1 = makeTxn(description: "UPI-SPOTIFY", amount: 13900, type: .debit)
        let txn2 = makeTxn(description: "UPI-SPOTIFY", amount: 13900, type: .debit)
        let enriched = [
            makeEnriched(txn: txn1, merchant: "Spotify", categoryId: "subscriptions"),
            makeEnriched(txn: txn2, merchant: "Spotify", categoryId: "subscriptions")
        ]
        try await builder.build(from: enriched)

        let merchantNode = try await store.node(externalId: "spotify", type: .merchant)
        #expect(merchantNode != nil)

        // Category edge should have observationCount ≥ 2 (both transactions classified it)
        let catEdges = try await store.edges(from: merchantNode!.id)
        let classifiedEdge = catEdges.first { $0.edgeType == .classifiedAs }
        #expect(classifiedEdge?.observationCount ?? 0 >= 2)
    }

    @Test("50 diverse transactions produce correct graph topology")
    func fiftyTransactionGraphTopology() async throws {
        let store = try makeStore()
        let builder = GraphBuilder(store: store)

        let ledgerId = UUID()
        var transactions: [EnrichedTransaction] = []

        // 12 Spotify monthly debits
        for _ in 0..<12 {
            let txn = makeTxn(description: "UPI-SPOTIFY", amount: 13900,
                              type: .debit, ledgerId: ledgerId, categoryId: "subscriptions")
            transactions.append(makeEnriched(txn: txn, merchant: "Spotify",
                                             categoryId: "subscriptions"))
        }
        // 12 salary credits
        for _ in 0..<12 {
            let txn = makeTxn(description: "NEFT CR-PAYPAL SALARY", amount: 15000000,
                              type: .credit, ledgerId: ledgerId, categoryId: "income")
            transactions.append(makeEnriched(txn: txn, merchant: "PayPal",
                                             categoryId: "income"))
        }
        // 10 Blinkit debits
        for _ in 0..<10 {
            let txn = makeTxn(description: "UPI-BLINKIT", amount: 50000,
                              type: .debit, ledgerId: ledgerId, categoryId: "groceries")
            transactions.append(makeEnriched(txn: txn, merchant: "Blinkit",
                                             categoryId: "groceries"))
        }
        // 16 miscellaneous transfers
        for i in 0..<16 {
            let txn = makeTxn(description: "UPI-PERSON-\(i)", amount: 100000,
                              type: .debit, ledgerId: ledgerId, categoryId: "transfers")
            transactions.append(makeEnriched(txn: txn, merchant: "Person \(i)",
                                             categoryId: "transfers"))
        }

        #expect(transactions.count == 50)

        try await builder.build(from: transactions)

        // Merchant nodes created
        let spotifyNode = try await store.node(externalId: "spotify", type: .merchant)
        #expect(spotifyNode != nil)

        let blinkitNode = try await store.node(externalId: "blinkit", type: .merchant)
        #expect(blinkitNode != nil)

        // Spotify category edge observationCount == 12
        let spotifyEdges = try await store.edges(from: spotifyNode!.id)
        let spotifyClassified = spotifyEdges.first { $0.edgeType == .classifiedAs }
        #expect(spotifyClassified?.observationCount == 12)

        // Blinkit category edge observationCount == 10
        let blinkitEdges = try await store.edges(from: blinkitNode!.id)
        let blinkitClassified = blinkitEdges.first { $0.edgeType == .classifiedAs }
        #expect(blinkitClassified?.observationCount == 10)

        // Transaction nodes: 50
        let txnNodes = try await store.nodes(ofType: .transaction)
        #expect(txnNodes.count == 50)
    }

    @Test("BFS at depth 2 finds category through merchant")
    func bfsDepth2FindsCategory() async throws {
        let store = try makeStore()
        let builder = GraphBuilder(store: store)

        let txn = makeTxn(description: "UPI-DOMINOS", amount: 48100, type: .debit)
        let enriched = makeEnriched(txn: txn, merchant: "Dominos Pizza", categoryId: "dining")
        try await builder.build(from: [enriched])

        let txnNode = try await store.node(externalId: txn.id.uuidString, type: .transaction)
        let reachable = try await store.bfsNeighbors(of: txnNode!.id, maxDepth: 2)

        let types = Set(reachable.map(\.nodeType))
        #expect(types.contains(.merchant))
        #expect(types.contains(.category))
    }
}
