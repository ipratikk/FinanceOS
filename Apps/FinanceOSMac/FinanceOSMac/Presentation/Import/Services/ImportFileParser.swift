import FinanceCore
import FinanceParsers
import Foundation
import OSLog

/// Stateless file-parsing service. Wraps statement detection, parsing, and filename
/// metadata enrichment. Extracted from ImportViewModel to allow independent unit testing.
struct ImportFileParser {
    private let logger = FinanceLogger.importPipeline

    func parse(fileURL: URL) async throws -> ParsedStatement {
        let fileName = fileURL.lastPathComponent

        do {
            let detectedSource = try StatementDetector.detect(fileURL: fileURL)
            let result = try UnifiedStatementParser().parse(fileURL: fileURL, detectedSource: detectedSource)

            let filenameMetadata = FilenameMetadataExtractor().extractMetadata(from: fileName)

            var statement = result.statement
            let enhancedMetadata: FinanceParsers.StatementMetadata? = if let existingMetadata = statement.metadata {
                mergeMetadata(parsed: existingMetadata, filename: filenameMetadata)
            } else {
                FinanceParsers.StatementMetadata(
                    accountNumber: filenameMetadata.accountLast4,
                    fullAccountNumber: filenameMetadata.accountNumber,
                    generatedAt: filenameMetadata.statementDate
                )
            }

            let finalAccountLast4 = enhancedMetadata?.accountNumber ?? statement.accountLast4
            let finalCardLast4 = statement.cardLast4

            statement = ParsedStatement(
                bankName: statement.bankName,
                accountName: statement.accountName,
                accountLast4: finalAccountLast4,
                cardLast4: finalCardLast4,
                statementPeriodStart: statement.statementPeriodStart,
                statementPeriodEnd: statement.statementPeriodEnd,
                currency: statement.currency,
                totalDebit: statement.totalDebit,
                totalCredit: statement.totalCredit,
                transactions: statement.transactions,
                metadata: enhancedMetadata
            )

            logger.logInfo(
                "Parsed {file}: {count} txns from {bank}",
                ["file": fileName, "count": statement.transactions.count, "bank": detectedSource.bankName]
            )
            return statement
        } catch let error as DetectionError {
            throw TransactionImportError.unsupportedFormat(error.description)
        }
    }

    private func mergeMetadata(
        parsed: FinanceParsers.StatementMetadata,
        filename: FilenameMetadata
    ) -> FinanceParsers.StatementMetadata {
        FinanceParsers.StatementMetadata(
            customerName: parsed.customerName ?? filename.accountNumber,
            customerId: parsed.customerId,
            accountNumber: parsed.accountNumber ?? filename.accountLast4,
            fullAccountNumber: parsed.fullAccountNumber ?? filename.accountNumber,
            accountType: parsed.accountType,
            cardType: parsed.cardType,
            branch: parsed.branch,
            branchCode: parsed.branchCode,
            address: parsed.address,
            email: parsed.email,
            phone: parsed.phone,
            ifsc: parsed.ifsc,
            micr: parsed.micr,
            openingBalance: parsed.openingBalance,
            closingBalance: parsed.closingBalance,
            debitCount: parsed.debitCount,
            creditCount: parsed.creditCount,
            generatedAt: parsed.generatedAt ?? filename.statementDate
        )
    }
}
