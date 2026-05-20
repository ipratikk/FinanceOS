import Foundation

public struct UnifiedStatementParser: Sendable {
    public init() {}

    public func parse(fileURL: URL, detectedSource: StatementSource) throws -> ParseResult {
        let startTime = Date()

        let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
        let rawRows = try CSVReader.readRows(from: fileURL, delimiter: ",")
        let rows = try loadRows(from: fileURL, source: detectedSource)
        guard !rows.isEmpty else {
            throw TransactionImportError.malformedFile("No data rows found")
        }

        let headerRow = rows[0]
        let dataRows = Array(rows.dropFirst())

        let ctx = BuildContext(
            dataRows: dataRows,
            allRows: rows,
            rawRows: rawRows,
            headerRow: headerRow,
            source: detectedSource,
            fileContent: fileContent
        )
        let statement = try buildStatement(context: ctx)

        let durationMs = Date().timeIntervalSince(startTime) * 1000

        let diagnostics = ParserDiagnostics(
            failedRows: [],
            unmatchedLines: [],
            balanceValidation: nil,
            duplicatesDetected: 0,
            warnings: [],
            parserTimingMs: durationMs,
            rowsProcessed: dataRows.count,
            transactionsParsed: statement.transactions.count,
            skippedRows: 0
        )

        return ParseResult(
            schemaVersion: "1.0",
            parserVersion: "dev",
            institutionVersion: sourceVersion(detectedSource),
            statement: statement,
            diagnostics: diagnostics,
            confidence: 1.0
        )
    }

    private func loadRows(from fileURL: URL, source: StatementSource) throws -> [[String]] {
        switch source {
        case .hdfcCard:
            let parser = HDFCCardCSVParser()
            return try parser.parse(fileURL: fileURL)
        case .iciciCard:
            let parser = ICICICardCSVParser()
            return try parser.parse(fileURL: fileURL)
        case .iciciBank:
            let parser = ICICIBankCSVParser()
            return try parser.parse(fileURL: fileURL)
        case .hdfcBank:
            let parser = HDFCBankTXTParser()
            return try parser.parse(fileURL: fileURL)
        case .amex:
            let parser = AmexCardCSVParser()
            return try parser.parse(fileURL: fileURL)
        }
    }

    private struct BuildContext {
        let dataRows: [[String]]
        let allRows: [[String]]
        let rawRows: [[String]]
        let headerRow: [String]
        let source: StatementSource
        let fileContent: String
    }

    private func buildStatement(context: BuildContext) throws -> ParsedStatement {
        var transactions: [ParsedTransaction] = []
        var metadata: StatementMetadata?
        var cardLast4: String?
        var accountLast4: String?

        try populateTransactions(
            context: context,
            transactions: &transactions,
            metadata: &metadata,
            cardLast4: &cardLast4,
            accountLast4: &accountLast4
        )

        let totalDebit = transactions.filter { $0.amountMinorUnits > 0 }.map(\.amountMinorUnits).reduce(0, +)
        let totalCredit = transactions.filter { $0.amountMinorUnits < 0 }.map { -$0.amountMinorUnits }.reduce(0, +)

        return ParsedStatement(
            bankName: context.source.bankName,
            accountName: metadata?.customerName ?? context.source.bankName,
            accountLast4: accountLast4,
            cardLast4: cardLast4,
            statementPeriodStart: nil,
            statementPeriodEnd: nil,
            currency: "INR",
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions,
            metadata: metadata
        )
    }

    private func populateTransactions(
        context: BuildContext,
        transactions: inout [ParsedTransaction],
        metadata: inout StatementMetadata?,
        cardLast4: inout String?,
        accountLast4: inout String?
    ) throws {
        switch context.source {
        case .hdfcCard:
            metadata = HDFCCardMetadataExtractor().extract(from: context.fileContent)
            cardLast4 = metadata?.accountNumber
            let hdfcCardMapper = HDFCCardCSVMapper()
            let hdfcCardNormalizer = HDFCCardCSVNormalizer()
            let hdfcCardRoles = try hdfcCardMapper.map(headerRow: context.headerRow)
            for row in context.dataRows {
                let normalizedRow = hdfcCardMapper.mapRow(row, using: hdfcCardRoles)
                if let tx = try hdfcCardNormalizer.normalize(normalizedRow: normalizedRow) { transactions.append(tx) }
            }
        case .iciciCard:
            metadata = ICICICardMetadataExtractor().extract(from: context.allRows)
            cardLast4 = metadata?.accountNumber
            let iciciCardMapper = ICICICardCSVMapper()
            let iciciCardNormalizer = ICICICardCSVNormalizer()
            let iciciCardRoles = try iciciCardMapper.map(headerRow: context.headerRow)
            for row in context.dataRows {
                let normalizedRow = iciciCardMapper.mapRow(row, using: iciciCardRoles)
                if let tx = try iciciCardNormalizer.normalize(normalizedRow: normalizedRow) { transactions.append(tx) }
            }
        case .iciciBank:
            metadata = ICICIMetadataExtractor().extract(from: context.rawRows)
            accountLast4 = metadata?.accountNumber
            let iciciBankMapper = ICICIBankCSVMapper()
            let iciciBankNormalizer = ICICIBankCSVNormalizer()
            let iciciBankRoles = try iciciBankMapper.map(headerRow: context.headerRow)
            for row in context.dataRows {
                let normalizedRow = iciciBankMapper.mapRow(row, using: iciciBankRoles)
                if let tx = try iciciBankNormalizer.normalize(normalizedRow: normalizedRow) { transactions.append(tx) }
            }
        case .hdfcBank:
            metadata = HDFCBankMetadataExtractor().extract(from: context.fileContent)
            accountLast4 = metadata?.accountNumber
            let hdfcBankMapper = HDFCBankTXTMapper()
            let hdfcBankNormalizer = HDFCBankTXTNormalizer()
            let hdfcBankRoles = try hdfcBankMapper.map(headerRow: context.headerRow)
            for row in context.dataRows {
                let normalizedRow = hdfcBankMapper.mapRow(row, using: hdfcBankRoles)
                if let tx = try hdfcBankNormalizer.normalize(normalizedRow: normalizedRow) { transactions.append(tx) }
            }
        case .amex:
            metadata = AmexCardMetadataExtractor().extract(from: context.allRows)
            cardLast4 = metadata?.accountNumber
            let amexMapper = AmexCardCSVMapper()
            let amexNormalizer = AmexCardCSVNormalizer()
            let amexRoles = try amexMapper.map(headerRow: context.headerRow)
            for row in context.dataRows {
                let normalizedRow = amexMapper.mapRow(row, using: amexRoles)
                if let tx = try amexNormalizer.normalize(normalizedRow: normalizedRow) { transactions.append(tx) }
            }
        }
    }

    private func sourceVersion(_ source: StatementSource) -> String {
        switch source {
        case .hdfcCard:
            return "HDFC-Card-1.0"
        case .iciciCard:
            return "ICICI-Card-1.0"
        case .iciciBank:
            return "ICICI-Bank-1.0"
        case .hdfcBank:
            return "HDFC-Bank-1.0"
        case .amex:
            return "Amex-1.0"
        }
    }
}
