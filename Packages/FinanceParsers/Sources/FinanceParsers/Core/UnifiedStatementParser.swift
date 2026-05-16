import Foundation

public struct UnifiedStatementParser: Sendable {
    public init() {}

    public func parse(fileURL: URL, detectedSource: StatementSource) throws -> ParseResult {
        let startTime = Date()

        let rows = try loadRows(from: fileURL, source: detectedSource)
        guard !rows.isEmpty else {
            throw TransactionImportError.malformedFile("No data rows found")
        }

        let headerRow = rows[0]
        let dataRows = Array(rows.dropFirst())

        let statement = try buildStatement(
            from: dataRows,
            headerRow: headerRow,
            source: detectedSource
        )

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

    private func buildStatement(
        from dataRows: [[String]],
        headerRow: [String],
        source: StatementSource
    ) throws -> ParsedStatement {
        var transactions: [ParsedTransaction] = []

        switch source {
        case .hdfcCard:
            let mapper = HDFCCardCSVMapper()
            let normalizer = HDFCCardCSVNormalizer()
            let roles = try mapper.map(headerRow: headerRow)
            for row in dataRows {
                let normalized = mapper.mapRow(row, using: roles)
                if let txn = try normalizer.normalize(normalizedRow: normalized) {
                    transactions.append(txn)
                }
            }
        case .iciciCard:
            let mapper = ICICICardCSVMapper()
            let normalizer = ICICICardCSVNormalizer()
            let roles = try mapper.map(headerRow: headerRow)
            for row in dataRows {
                let normalized = mapper.mapRow(row, using: roles)
                if let txn = try normalizer.normalize(normalizedRow: normalized) {
                    transactions.append(txn)
                }
            }
        case .iciciBank:
            let mapper = ICICIBankCSVMapper()
            let normalizer = ICICIBankCSVNormalizer()
            let roles = try mapper.map(headerRow: headerRow)
            for row in dataRows {
                let normalized = mapper.mapRow(row, using: roles)
                if let txn = try normalizer.normalize(normalizedRow: normalized) {
                    transactions.append(txn)
                }
            }
        case .hdfcBank:
            let mapper = HDFCBankTXTMapper()
            let normalizer = HDFCBankTXTNormalizer()
            let roles = try mapper.map(headerRow: headerRow)
            for row in dataRows {
                let normalized = mapper.mapRow(row, using: roles)
                if let txn = try normalizer.normalize(normalizedRow: normalized) {
                    transactions.append(txn)
                }
            }
        case .amex:
            let mapper = AmexCardCSVMapper()
            let normalizer = AmexCardCSVNormalizer()
            let roles = try mapper.map(headerRow: headerRow)
            for row in dataRows {
                let normalized = mapper.mapRow(row, using: roles)
                if let txn = try normalizer.normalize(normalizedRow: normalized) {
                    transactions.append(txn)
                }
            }
        }

        let totalDebit = transactions.filter { $0.amountMinorUnits > 0 }.map(\.amountMinorUnits).reduce(0, +)
        let totalCredit = transactions.filter { $0.amountMinorUnits < 0 }.map { -$0.amountMinorUnits }.reduce(0, +)

        return ParsedStatement(
            bankName: source.bankName,
            accountName: source.bankName,
            accountLast4: nil,
            cardLast4: nil,
            statementPeriodStart: nil,
            statementPeriodEnd: nil,
            currency: "INR",
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            transactions: transactions,
            metadata: nil
        )
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
