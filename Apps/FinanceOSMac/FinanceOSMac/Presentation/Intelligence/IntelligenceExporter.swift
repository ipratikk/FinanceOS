import AppKit
import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
import Foundation

/// Exports all intelligence entities to a timestamped directory as CSV files.
/// Each CSV includes empty `validated` + `notes` columns for ground-truth annotation.
@MainActor
struct IntelligenceExporter {
    struct ExportResult {
        let folder: URL
        let personCount: Int
        let relationshipCount: Int
        let patternCount: Int
        let nodeCount: Int
        let edgeCount: Int
    }

    static func chooseDestinationFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.message = "Select folder to export FinanceOS Intelligence data"
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func exportAll(container: IntelligenceContainer, to folder: URL) async throws -> ExportResult {
        let stamp = Date().formatted(Date.ISO8601FormatStyle()).replacingOccurrences(of: ":", with: "-")
        let dir = folder.appending(path: "FinanceOS-Intelligence-\(stamp)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let persons = try await container.personRepository.fetchAll()
        let relationships = try await container.relationshipRepository.fetchAll()
        let patterns = try await container.recurringPatternRepository.fetchAll()
        let nodes = try await container.graphRepository.allNodes(limit: 5000)
        let edges = try await container.graphRepository.allEdges(limit: 10000)
        let transactions = try await fetchAllTransactions()

        try writePersons(persons, to: dir)
        try writeRelationships(relationships, to: dir)
        try writePatterns(patterns, to: dir)
        try writeNodes(nodes, to: dir)
        try writeEdges(edges, to: dir)
        try writeTransactionAudit(transactions, persons: persons, patterns: patterns, to: dir)
        try writeMLTrainingData(transactions, to: dir)
        try writeSummary(
            persons: persons,
            relationships: relationships,
            patterns: patterns,
            nodes: nodes,
            edges: edges,
            transactions: transactions,
            to: dir
        )

        return ExportResult(
            folder: dir,
            personCount: persons.count,
            relationshipCount: relationships.count,
            patternCount: patterns.count,
            nodeCount: nodes.count,
            edgeCount: edges.count
        )
    }

    // MARK: - CSV Writers

    private static func writePersons(_ persons: [Person], to dir: URL) throws {
        var rows = ["id,canonicalName,aliases,upiHandle,transactionCount,firstSeenAt,lastSeenAt,validated,notes"]
        for person in persons.sorted(by: { $0.canonicalName < $1.canonicalName }) {
            rows.append([
                person.id.uuidString,
                csv(person.canonicalName),
                csv(person.aliases.joined(separator: " | ")),
                csv(person.upiHandle ?? ""),
                "\(person.transactionCount)",
                iso(person.firstSeenAt),
                iso(person.lastSeenAt),
                "", ""
            ].joined(separator: ","))
        }
        try write(rows, filename: "persons.csv", to: dir)
    }

    private static func writeRelationships(_ relationships: [Relationship], to dir: URL) throws {
        var rows = ["id,type,fromPersonId,toPersonId,confidence,evidenceCount,signals,createdAt,validated,notes"]
        for rel in relationships {
            rows.append([
                rel.id.uuidString,
                rel.type.rawValue,
                csv(rel.fromPersonId ?? ""),
                csv(rel.toPersonId ?? ""),
                String(format: "%.3f", rel.confidence),
                "\(rel.evidenceCount)",
                csv(rel.signals.map(\.rawValue).joined(separator: " | ")),
                iso(rel.createdAt),
                "", ""
            ].joined(separator: ","))
        }
        try write(rows, filename: "relationships.csv", to: dir)
    }

    private static func writePatterns(_ patterns: [RecurringPattern], to dir: URL) throws {
        var rows = [
            "id,merchantKey,personId,categoryId,intentId,cadence," +
                "avgAmountRs,variancePct,dayOfMonthHint,confidence,occurrenceCount,lastSeenAt,validated,notes"
        ]
        for pat in patterns {
            rows.append([
                pat.id.uuidString,
                csv(pat.merchantKey ?? ""),
                csv(pat.personId ?? ""),
                csv(pat.categoryId),
                csv(pat.intentId),
                pat.cadence.rawValue,
                String(format: "%.2f", Double(pat.averageAmountMinorUnits) / 100.0),
                String(format: "%.1f", pat.amountVariancePercent),
                pat.dayOfMonthHint.map(String.init) ?? "",
                String(format: "%.3f", pat.confidence),
                "\(pat.occurrenceCount)",
                iso(pat.lastSeenAt),
                "", ""
            ].joined(separator: ","))
        }
        try write(rows, filename: "patterns.csv", to: dir)
    }

    private static func writeNodes(_ nodes: [GraphNode], to dir: URL) throws {
        var rows = ["id,type,externalId,label,properties,createdAt"]
        for node in nodes.sorted(by: { $0.nodeType.rawValue < $1.nodeType.rawValue }) {
            let props = node.properties.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
            rows.append([
                node.id,
                node.nodeType.rawValue,
                csv(node.externalId),
                csv(node.label),
                csv(props),
                iso(node.createdAt)
            ].joined(separator: ","))
        }
        try write(rows, filename: "graph-nodes.csv", to: dir)
    }

    private static func writeEdges(_ edges: [GraphEdge], to dir: URL) throws {
        var rows = ["id,fromNodeId,toNodeId,edgeType,weight,observationCount,lastObservedAt"]
        for edge in edges {
            rows.append([
                edge.id,
                edge.fromNodeId,
                edge.toNodeId,
                edge.edgeType.rawValue,
                String(format: "%.2f", edge.weight),
                "\(edge.observationCount)",
                iso(edge.lastObservedAt)
            ].joined(separator: ","))
        }
        try write(rows, filename: "graph-edges.csv", to: dir)
    }

    // MARK: - Transaction Audit

    private static func writeTransactionAudit(
        _ transactions: [Transaction],
        persons: [Person],
        patterns: [RecurringPattern],
        to dir: URL
    ) throws {
        let personsByName: [String: Person] = Dictionary(
            persons.map { ($0.canonicalName.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let patternsByKey: [String: RecurringPattern] = Dictionary(
            patterns.compactMap { pat in pat.merchantKey.map { ($0, pat) } },
            uniquingKeysWith: { first, _ in first }
        )
        let taxonomy = CategoryTaxonomy.current

        var rows = [
            "date,type,amountRs,rawNarration,merchantName,categoryId,categoryDisplayName," +
                "isPersonTransfer,isRecurring,correct_category,correct_merchant,notes"
        ]
        for txn in transactions.sorted(by: { $0.postedAt < $1.postedAt }) {
            let merchantKey = txn.merchantName?.lowercased() ?? ""
            let categoryName = txn.categoryId.flatMap { taxonomy.category(forId: $0)?.displayName } ?? ""
            let isPerson = personsByName[merchantKey] != nil
            let isRecurring = patternsByKey[merchantKey] != nil
            rows.append([
                iso(txn.postedAt),
                txn.transactionType == .debit ? "debit" : "credit",
                String(format: "%.2f", Double(txn.amountMinorUnits) / 100.0),
                csv(txn.description),
                csv(txn.merchantName ?? ""),
                txn.categoryId ?? "",
                csv(categoryName),
                isPerson ? "Y" : "N",
                isRecurring ? "Y" : "N",
                "",
                "",
                ""
            ].joined(separator: ","))
        }
        try write(rows, filename: "transactions-audit.csv", to: dir)
    }

    // MARK: - ML Training Data

    private static func writeMLTrainingData(_ transactions: [Transaction], to dir: URL) throws {
        struct TrainingSample: Encodable {
            let text: String
            let label: String
        }

        let taxonomy = CategoryTaxonomy.current
        var samples: [TrainingSample] = []

        for txn in transactions {
            guard let categoryId = txn.categoryId,
                  !categoryId.isEmpty,
                  categoryId != "uncategorized",
                  !txn.description.isEmpty,
                  taxonomy.category(forId: categoryId) != nil ||
                  taxonomy.subcategory(forId: categoryId) != nil else { continue }
            samples.append(TrainingSample(text: txn.description, label: categoryId))
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(samples)
        try data.write(to: dir.appending(path: "training-category.json"))
    }

    // swiftlint:disable:next function_parameter_count
    private static func writeSummary(
        persons: [Person], relationships: [Relationship],
        patterns: [RecurringPattern], nodes: [GraphNode], edges: [GraphEdge],
        transactions: [Transaction],
        to dir: URL
    ) throws {
        let categorized = transactions.count(where: { $0.categoryId != nil })
        var lines = [
            "FinanceOS Intelligence Export",
            "Generated: \(Date().formatted(Date.ISO8601FormatStyle()))",
            "",
            "Entity Counts",
            "-------------",
            "Transactions:          \(transactions.count) (\(categorized) categorized)",
            "Persons:               \(persons.count)",
            "Relationships:         \(relationships.count)",
            "Recurring Patterns:    \(patterns.count)",
            "Graph Nodes:           \(nodes.count)",
            "Graph Edges:           \(edges.count)",
            "",
            "Relationship Type Breakdown",
            "---------------------------"
        ]
        let byType = Dictionary(grouping: relationships, by: \.type)
        RelationshipType.allCases.forEach { lines.append("  \($0.rawValue.padded(to: 18)) \(byType[$0]?.count ?? 0)") }

        lines += ["", "Recurring Cadence Breakdown", "---------------------------"]
        let byCadence = Dictionary(grouping: patterns, by: \.cadence)
        RecurringCadence.allCases
            .forEach { lines.append("  \($0.rawValue.padded(to: 18)) \(byCadence[$0]?.count ?? 0)") }

        lines += ["", "Graph Node Type Breakdown", "-------------------------"]
        let byNodeType = Dictionary(grouping: nodes, by: \.nodeType)
        GraphNode.NodeType.allCases
            .forEach { lines.append("  \($0.rawValue.padded(to: 18)) \(byNodeType[$0]?.count ?? 0)") }

        try lines.joined(separator: "\n").write(
            to: dir.appending(path: "summary.txt"),
            atomically: true,
            encoding: .utf8
        )
    }

    // MARK: - Helpers

    private static func csv(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func iso(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle())
    }

    private static func write(_ rows: [String], filename: String, to dir: URL) throws {
        try rows.joined(separator: "\n").write(to: dir.appending(path: filename), atomically: true, encoding: .utf8)
    }
}

@MainActor
private func fetchAllTransactions() async throws -> [Transaction] {
    let data = try await AppContainer.shared.graphQLClient.fetch(
        query: GetTransactionsQuery(ledgerId: .none, filter: .none, limit: .none)
    )
    return data.transactions.map(GraphQLMappings.mapTransaction)
}

private extension String {
    func padded(to width: Int) -> String {
        padding(toLength: max(width, count), withPad: " ", startingAt: 0)
    }
}
